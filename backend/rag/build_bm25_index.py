"""
핀버디 - BM25 키워드 인덱스 생성 스크립트

FAISS(의미검색)와 짝을 이루는 두 번째 검색 경로. 임베딩 모델이 필요 없고,
Kiwi로 형태소 분석한 토큰의 등장 빈도만으로 점수를 매긴다 (rank_bm25.BM25Okapi).

26개 청크 정도의 작은 corpus는 빌드 자체가 1초도 안 걸리기 때문에 매번
새로 빌드해도 되지만, FAISS처럼 파일로 저장해두면 재사용이 쉬워서 pickle로
backend/rag/bm25_index/bm25.pkl 에 저장한다.
"""

import pickle
from pathlib import Path

from rank_bm25 import BM25Okapi

from kiwi_tokenizer import tokenize_ko
from load_chunks import load_chunks_as_documents

RAG_DIR = Path(__file__).parent
BM25_DIR = RAG_DIR / "bm25_index"
BM25_PATH = BM25_DIR / "bm25.pkl"


def build_and_save_bm25():
    docs = load_chunks_as_documents()
    print(f"BM25 인덱싱 대상 Document {len(docs)}개")

    tokenized_corpus = [tokenize_ko(d.page_content) for d in docs]
    bm25 = BM25Okapi(tokenized_corpus)

    BM25_DIR.mkdir(exist_ok=True)
    with open(BM25_PATH, "wb") as f:
        # bm25 객체 + chunk_id 순서(= docs 순서)를 그대로 저장.
        # 문서 원본(Document)은 load_chunks.py로 다시 만들면 되므로 저장하지 않음.
        pickle.dump({"bm25": bm25, "num_docs": len(docs)}, f)

    print(f"BM25 인덱스 저장 완료: {BM25_PATH}")
    return bm25, docs


_bm25_cache = None


def load_bm25():
    # API 서버에서 매 요청마다 pickle을 다시 읽지 않도록 프로세스당 한 번만 로드.
    global _bm25_cache
    if _bm25_cache is None:
        with open(BM25_PATH, "rb") as f:
            data = pickle.load(f)
        docs = load_chunks_as_documents()
        assert len(docs) == data["num_docs"], (
            "저장된 BM25 인덱스의 문서 수와 현재 청크 수가 다릅니다. "
            "processed/ 청크가 바뀌었으면 build_bm25_index.py를 다시 실행하세요."
        )
        _bm25_cache = (data["bm25"], docs)
    return _bm25_cache


def run_search_test(bm25: BM25Okapi, docs, k: int = 3):
    sample_queries = [
        "ISA 총납입한도는 얼마야?",
        "연금저축계좌 세액공제 한도는 연간 얼마야?",
        "외국인 종합소득세 신고 기간은 언제야?",
    ]
    print("\n=== BM25 검색 테스트 ===")
    for q in sample_queries:
        tokenized_q = tokenize_ko(q)
        scores = bm25.get_scores(tokenized_q)
        top_idx = sorted(range(len(scores)), key=lambda i: scores[i], reverse=True)[:k]
        print(f"\nQ: {q}")
        for rank, idx in enumerate(top_idx, 1):
            d = docs[idx]
            preview = d.page_content[:50].replace("\n", " ")
            print(f"  {rank}. (score={scores[idx]:.2f}) [{d.metadata.get('doc_type')}] {d.metadata.get('label', '')[:35]} | {preview}...")


if __name__ == "__main__":
    bm25, docs = build_and_save_bm25()
    run_search_test(bm25, docs)
