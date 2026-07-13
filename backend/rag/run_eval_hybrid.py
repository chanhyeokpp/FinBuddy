"""
핀버디 - 하이브리드(FAISS+BM25) 검색으로 12문항 재채점

run_eval.py(FAISS 단독, 11/12)와 같은 방식이지만 검색을 hybrid_search()로 바꿔서
BM25가 실제로 도움이 되는지(특히 이전에 틀렸던 "ISA 총납입한도" 문항) 확인한다.
"""

import json
from pathlib import Path

from hybrid_search import hybrid_search

RAG_DIR = Path(__file__).parent
EVAL_PATH = RAG_DIR / "eval" / "eval_12.json"
TOP_K = 3


def norm(s: str) -> str:
    return s.replace(" ", "").replace(",", "")


def main():
    eval_items = json.loads(EVAL_PATH.read_text(encoding="utf-8"))

    correct = 0
    results = []

    for item in eval_items:
        q, answer, source = item["q"], item["a"], item["source"]
        hits = hybrid_search(q, k=TOP_K)
        combined = norm("\n".join(doc.page_content for doc, *_ in hits))
        ok = norm(answer) in combined
        correct += ok

        results.append({
            "q": q, "a": answer, "source": source, "ok": ok,
            "top1_label": hits[0][0].metadata.get("label", "") if hits else "",
        })

    print(f"=== 하이브리드 검색 채점 결과 (top-{TOP_K}) ===\n")
    for r in results:
        mark = "O" if r["ok"] else "X"
        print(f"{mark} [{r['source']:>13}] {r['a']:<25} <- {r['q']}")
        if not r["ok"]:
            print(f"    (top1 검색결과: {r['top1_label']})")

    print(f"\n총점: {correct} / {len(eval_items)}")

    with open(RAG_DIR / "eval" / "eval_result_hybrid.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
    print("eval/eval_result_hybrid.json 저장 완료")


if __name__ == "__main__":
    main()
