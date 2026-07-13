"""
핀버디 - FAISS(의미검색) + BM25(키워드검색) 하이브리드 검색 & Reranker(bge-reranker-v2-m3)

두 검색 방식의 결과를 RRF(Reciprocal Rank Fusion)로 병합한 후,
BAAI/bge-reranker-v2-m3 모델을 이용해 딥러닝 기반으로 재정렬(Reranking)을 수행하여
최종 top-k Document를 결정합니다.
"""

from pathlib import Path
from build_index import load_index
from build_bm25_index import load_bm25
from kiwi_tokenizer import tokenize_ko

RRF_K = 60

_reranker_cache = None


def get_reranker():
    global _reranker_cache
    if _reranker_cache is None:
        print("Loading BAAI/bge-reranker-v2-m3 model (this might take a moment on first load)...")
        from sentence_transformers import CrossEncoder
        _reranker_cache = CrossEncoder("BAAI/bge-reranker-v2-m3")
    return _reranker_cache


def hybrid_search(query: str, k: int = 3, faiss_top_n: int = 15, bm25_top_n: int = 15, rrf_top_n: int = 10, use_reranker: bool = True):
    """
    query에 대해 FAISS와 BM25 양쪽에서 각각 top-n을 뽑은 뒤 RRF로 합치고,
    선택적으로 CrossEncoder(bge-reranker-v2-m3) 리랭커를 거쳐 최종 top-k Document를 반환한다.
    """
    faiss_store = load_index()
    bm25, docs = load_bm25()

    # --- FAISS 순위 (chunk_id -> rank) ---
    faiss_hits = faiss_store.similarity_search(query, k=faiss_top_n)
    faiss_ranks = {
        hit.metadata["chunk_id"]: rank
        for rank, hit in enumerate(faiss_hits, start=1)
    }

    # --- BM25 순위 (chunk_id -> rank) ---
    tokenized_q = tokenize_ko(query)
    bm25_scores = bm25.get_scores(tokenized_q)
    bm25_order = sorted(range(len(bm25_scores)), key=lambda i: bm25_scores[i], reverse=True)[:bm25_top_n]
    bm25_ranks = {
        docs[idx].metadata["chunk_id"]: rank
        for rank, idx in enumerate(bm25_order, start=1)
    }

    # --- RRF로 합산 ---
    all_chunk_ids = set(faiss_ranks) | set(bm25_ranks)
    rrf_scores = {}
    for cid in all_chunk_ids:
        score = 0.0
        if cid in faiss_ranks:
            score += 1 / (RRF_K + faiss_ranks[cid])
        if cid in bm25_ranks:
            score += 1 / (RRF_K + bm25_ranks[cid])
        rrf_scores[cid] = score

    # RRF 기준으로 1차 후보군 정렬
    rrf_sorted_cids = sorted(rrf_scores, key=lambda cid: rrf_scores[cid], reverse=True)
    
    id_to_doc = {d.metadata["chunk_id"]: d for d in docs}

    if use_reranker:
        # RRF top_n 후보군 추출
        candidates = rrf_sorted_cids[:rrf_top_n]
        if not candidates:
            return []
            
        reranker = get_reranker()
        pairs = [[query, id_to_doc[cid].page_content] for cid in candidates]
        
        # 리랭커 스코어 계산
        rerank_scores = reranker.predict(pairs)
        
        # 1차원 리스크/배열 보장
        import numpy as np
        if isinstance(rerank_scores, np.ndarray):
            rerank_scores = rerank_scores.tolist()
        elif not isinstance(rerank_scores, list):
            rerank_scores = [rerank_scores]
            
        candidate_scores = {cid: float(score) for cid, score in zip(candidates, rerank_scores)}
        
        # 리랭커 점수로 정렬
        final_ranked_cids = sorted(candidates, key=lambda cid: candidate_scores[cid], reverse=True)[:k]
        
        results = [
            (id_to_doc[cid], candidate_scores[cid], faiss_ranks.get(cid), bm25_ranks.get(cid))
            for cid in final_ranked_cids
        ]
    else:
        # 리랭커 미사용 시 RRF 상위 k개 직접 반환
        final_ranked_cids = rrf_sorted_cids[:k]
        results = [
            (id_to_doc[cid], rrf_scores[cid], faiss_ranks.get(cid), bm25_ranks.get(cid))
            for cid in final_ranked_cids
        ]

    return results


def run_search_test():
    sample_queries = [
        "ISA 총납입한도는 얼마야?",
        "연금저축계좌 세액공제 한도는 연간 얼마야?",
        "외국인 종합소득세 신고 기간은 언제야?",
    ]
    print("=== 하이브리드(FAISS+BM25, RRF) + Reranker 검색 테스트 ===")
    for q in sample_queries:
        print(f"\nQ: {q}")
        results = hybrid_search(q, k=3, use_reranker=True)
        for rank, (doc, score, f_rank, b_rank) in enumerate(results, 1):
            preview = doc.page_content[:50].replace("\n", " ")
            print(
                f"  {rank}. (score={score:.4f}, faiss_rank={f_rank}, bm25_rank={b_rank}) "
                f"[{doc.metadata.get('doc_type')}] {doc.metadata.get('label', '')[:35]} | {preview}..."
            )


if __name__ == "__main__":
    run_search_test()
