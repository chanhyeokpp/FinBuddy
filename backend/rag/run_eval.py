"""
핀버디 - RAG 파이프라인 실전 채점 스크립트

eval_dataset.py는 "정답이 문서 안에 존재하는가"만 확인했음 (1단계 검증).
이 스크립트는 한 단계 더 나아가 "실제 검색(FAISS+bge-m3)이 정답이 들어있는
청크를 top-k 안에 찾아오는가"를 확인한다 (2단계 검증, 진짜 RAG 성능 측정).

채점 기준:
  - 각 질문을 build_index.py로 만든 FAISS 인덱스에 검색 (top-k, 기본 k=3)
  - top-k로 검색된 청크들의 텍스트를 합쳐서, 정답 문자열이 그 안에 있는지 확인
  - 있으면 정답(O), 없으면 오답(X) - 오답인 경우 실제 top-1 청크가 뭐였는지 같이 출력
    (오답 원인 파악용: 완전히 엉뚱한 문서를 가져왔는지, 유사 문서인데 항이 다른지 등)

실행 전 준비물: build_index.py를 먼저 실행해서 faiss_index/ 가 생성되어 있어야 함.
"""

import json
from pathlib import Path

from build_index import load_index

RAG_DIR = Path(__file__).parent
EVAL_PATH = RAG_DIR / "eval" / "eval_12.json"
TOP_K = 3


def norm(s: str) -> str:
    """표기 차이를 흡수: 공백/쉼표 제거"""
    return s.replace(" ", "").replace(",", "")


def main():
    eval_items = json.loads(EVAL_PATH.read_text(encoding="utf-8"))
    vectorstore = load_index()

    correct = 0
    results = []

    for item in eval_items:
        q, answer, source = item["q"], item["a"], item["source"]
        hits = vectorstore.similarity_search(q, k=TOP_K)
        combined = norm("\n".join(h.page_content for h in hits))
        ok = norm(answer) in combined
        correct += ok

        results.append({
            "q": q, "a": answer, "source": source, "ok": ok,
            "top1_label": hits[0].metadata.get("label", "") if hits else "",
        })

    print(f"=== RAG 검색 채점 결과 (top-{TOP_K}) ===\n")
    for r in results:
        mark = "O" if r["ok"] else "X"
        print(f"{mark} [{r['source']:>13}] {r['a']:<25} <- {r['q']}")
        if not r["ok"]:
            print(f"    (top1 검색결과: {r['top1_label']})")

    print(f"\n총점: {correct} / {len(eval_items)}")

    with open(RAG_DIR / "eval" / "eval_result.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print("eval/eval_result.json 저장 완료")


if __name__ == "__main__":
    main()
