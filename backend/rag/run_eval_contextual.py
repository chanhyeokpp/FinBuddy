"""
핀버디 - Contextual Retrieval + Reranking 하이브리드 검색 채점 스크립트
12문항에 대해 Top-3 및 Top-1 정확도(Hit@1)를 평가하여 성능 향상을 측정합니다.
"""

import json
from pathlib import Path
from hybrid_search import hybrid_search

RAG_DIR = Path(__file__).parent
EVAL_PATH = RAG_DIR / "eval" / "eval_12.json"
TOP_K = 3


def norm(s: str) -> str:
    """표기 차이를 흡수: 공백/쉼표 제거"""
    return s.replace(" ", "").replace(",", "")


def main():
    eval_items = json.loads(EVAL_PATH.read_text(encoding="utf-8"))

    correct = 0
    top1_correct = 0
    results = []

    print("=== Contextual Retrieval + Reranker (bge-reranker-v2-m3) 평가 시작 ===")
    print("모델 다운로드 및 초기화로 인해 최초 평가 시 시간이 다소 걸릴 수 있습니다.\n")

    for idx, item in enumerate(eval_items, 1):
        q, answer, source = item["q"], item["a"], item["source"]
        print(f"[{idx}/{len(eval_items)}] Q: {q}")
        
        # Reranker가 적용된 하이브리드 검색 실행
        hits = hybrid_search(q, k=TOP_K, use_reranker=True)
        
        # Top-k 검색결과 내에 정답이 포함되어 있는지 검증 (기존 기준)
        combined = norm("\n".join(doc.page_content for doc, *_ in hits))
        ok = norm(answer) in combined
        correct += ok
        
        # Top-1 검색결과에 정답이 포함되어 있는지 검증 (Hit@1)
        top1_ok = False
        if hits:
            top1_content = norm(hits[0][0].page_content)
            top1_ok = norm(answer) in top1_content
            top1_correct += top1_ok
            
        results.append({
            "q": q,
            "a": answer,
            "source": source,
            "ok": bool(ok),
            "top1_ok": bool(top1_ok),
            "top1_label": hits[0][0].metadata.get("label", "") if hits else "",
            "top1_score": hits[0][1] if hits else 0.0,
        })

    print("\n=== 최종 채점 결과 (top-3) ===")
    for idx, r in enumerate(results, 1):
        mark = "O" if r["ok"] else "X"
        top1_mark = "O" if r["top1_ok"] else "X"
        print(f"{idx:2d}. [Top-3: {mark}][Top-1: {top1_mark}] [{r['source']:>13}] {r['a']:<25} <- {r['q']}")
        if not r["top1_ok"]:
            print(f"    (Top-1 검색결과: {r['top1_label']}, score={r['top1_score']:.4f})")

    print(f"\n[성능 요약]")
    print(f"총점 (Top-3 포함률): {correct} / {len(eval_items)} ({correct/len(eval_items)*100:.1f}%)")
    print(f"Top-1 정확도 (Hit@1): {top1_correct} / {len(eval_items)} ({top1_correct/len(eval_items)*100:.1f}%)")

    with open(RAG_DIR / "eval" / "eval_result_contextual.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print("\neval/eval_result_contextual.json 저장 완료")


if __name__ == "__main__":
    main()
