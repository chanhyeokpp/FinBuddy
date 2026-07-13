"""
핀버디 - FAISS 인덱스 생성 스크립트

역할 분리 (BCMD 워크숍 스택 기준):
  - 임베딩: BAAI/bge-m3 (오픈소스, 로컬 실행, 무료) — sentence-transformers 기반
  - LLM(답변 생성): OpenAI gpt-4o-mini — 이 스크립트에서는 사용하지 않음 (챗봇 답변 생성 단계에서 사용)
  - 리랭커: BAAI/bge-reranker-v2-m3 (임베딩과 세트, 추후 고도화 단계에서 추가 예정)

이 스크립트가 하는 일:
1) load_chunks.py로 26개 청크를 Document로 로드
2) HuggingFaceEmbeddings(BAAI/bge-m3)로 임베딩 (최초 실행 시 모델 가중치를
   huggingface.co에서 다운로드 -> 로컬 캐시. 이후 실행은 오프라인 가능)
3) FAISS 인덱스 생성 후 backend/rag/faiss_index/ 에 로컬 저장
4) 간단한 검색 테스트 (질의 -> top-k 문서) 실행

실행 환경 참고:
  - OpenAI API 키 불필요 (이 스크립트는 임베딩만 하므로)
  - 최초 실행 시 bge-m3 모델(약 2GB) 다운로드 필요 -> 인터넷 연결 필수
  - pip install langchain-huggingface sentence-transformers 필요
"""

from pathlib import Path

from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.vectorstores import FAISS

from load_chunks import load_chunks_as_documents

RAG_DIR = Path(__file__).parent
INDEX_DIR = RAG_DIR / "faiss_index"
EMBEDDING_MODEL = "BAAI/bge-m3"

# 인덱스 생성 후 동작 확인용 샘플 질의 (eval_dataset.py 12문항 중 일부)
SAMPLE_QUERIES = [
    "ISA 비과세 한도금액은 얼마야?",
    "연금저축계좌 세액공제 한도는 연간 얼마야?",
    "외국인 종합소득세 신고 기간은 언제야?",
]


_embeddings_cache: HuggingFaceEmbeddings | None = None
_index_cache: FAISS | None = None


def get_embeddings() -> HuggingFaceEmbeddings:
    # bge-m3(약 2GB)는 로딩 자체가 느려서, API 서버처럼 여러 번 호출되는
    # 환경에서는 프로세스당 한 번만 로드하도록 캐싱한다.
    global _embeddings_cache
    if _embeddings_cache is None:
        # bge 계열은 정규화된 임베딩(normalize_embeddings=True)을 쓸 때
        # 코사인 유사도 기반 검색 성능이 더 좋다고 알려져 있음
        _embeddings_cache = HuggingFaceEmbeddings(
            model_name=EMBEDDING_MODEL,
            encode_kwargs={"normalize_embeddings": True},
        )
    return _embeddings_cache


def build_and_save_index() -> FAISS:
    docs = load_chunks_as_documents()
    print(f"임베딩 대상 Document {len(docs)}개")

    embeddings = get_embeddings()
    vectorstore = FAISS.from_documents(docs, embeddings)

    INDEX_DIR.mkdir(exist_ok=True)
    vectorstore.save_local(str(INDEX_DIR))
    print(f"FAISS 인덱스 저장 완료: {INDEX_DIR}")

    return vectorstore


def load_index() -> FAISS:
    # FAISS 인덱스 자체도 디스크에서 다시 읽어들이는 비용이 있으므로 캐싱.
    global _index_cache
    if _index_cache is None:
        embeddings = get_embeddings()
        _index_cache = FAISS.load_local(
            str(INDEX_DIR), embeddings, allow_dangerous_deserialization=True
        )
    return _index_cache


def run_search_test(vectorstore: FAISS, k: int = 3):
    print("\n=== 검색 테스트 ===")
    for q in SAMPLE_QUERIES:
        print(f"\nQ: {q}")
        results = vectorstore.similarity_search(q, k=k)
        for i, r in enumerate(results, 1):
            preview = r.page_content[:60].replace("\n", " ")
            print(f"  {i}. [{r.metadata.get('doc_type')}] {r.metadata.get('label', '')[:40]} | {preview}...")


if __name__ == "__main__":
    vs = build_and_save_index()
    run_search_test(vs)
