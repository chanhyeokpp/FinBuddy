"""
핀버디 - 청크 JSON -> langchain_core.documents.Document 변환

processed/ 아래 두 가지 스키마가 섞여 있음:
  1) 법조항 청커 (law_chunker.py) 출력: law, article, hang_no, tag, text
  2) PDF 청커 (pdf_chunker.py) 출력: source, section_no, title, text

이 스크립트는 두 스키마를 모두 인식해서 하나의 Document 리스트로 통일한다.
- page_content = 청크의 실제 텍스트
- metadata에 원본 필드를 그대로 보존 + 공통 필드(source_file, doc_type, label) 추가
  - doc_type: "law" | "product_guide" | "tax_guide" (파일명 기준 분류)
  - label: 검색 결과에 사람이 보기 좋은 한 줄 출처 표기
"""

import json
from pathlib import Path

from langchain_core.documents import Document

PROCESSED_DIR = Path(__file__).parent / "processed"

CHUNK_FILES = [
    "chunks_isa_조세특례제한법91조18.json",
    "chunks_pension_소득세법59조3.json",
    "chunks_연금저축계좌_상품설명서.json",
    "chunks_외국인종합소득세신고안내.json",
]

CONTEXTUAL_CHUNK_FILES = [
    "contextual_chunks_isa_조세특례제한법91조18.json",
    "contextual_chunks_pension_소득세법59조3.json",
    "contextual_chunks_연금저축계좌_상품설명서.json",
    "contextual_chunks_외국인종합소득세신고안내.json",
]

# 파일명 -> doc_type 매핑 (eval_dataset.py의 source 태그와 맞춤)
DOC_TYPE_MAP = {
    "chunks_isa_조세특례제한법91조18.json": "isa",
    "chunks_pension_소득세법59조3.json": "pension",
    "chunks_연금저축계좌_상품설명서.json": "product_guide",
    "chunks_외국인종합소득세신고안내.json": "tax_guide",
    "contextual_chunks_isa_조세특례제한법91조18.json": "isa",
    "contextual_chunks_pension_소득세법59조3.json": "pension",
    "contextual_chunks_연금저축계좌_상품설명서.json": "product_guide",
    "contextual_chunks_외국인종합소득세신고안내.json": "tax_guide",
}


def _is_law_schema(chunk: dict) -> bool:
    return "law" in chunk and "article" in chunk


def _to_document(chunk: dict, fname: str, chunk_id: int) -> Document:
    doc_type = DOC_TYPE_MAP.get(fname, "unknown")
    page_content = chunk.get("contextual_text", chunk["text"])

    if _is_law_schema(chunk):
        label = f"{chunk['law']} {chunk['article']} {chunk['hang_no']}항 ({chunk['tag']})"
        metadata = {
            "chunk_id": chunk_id,
            "source_file": fname,
            "doc_type": doc_type,
            "law": chunk["law"],
            "article": chunk["article"],
            "hang_no": chunk["hang_no"],
            "tag": chunk["tag"],
            "label": label,
            "original_text": chunk["text"],
            "context_summary": chunk.get("context_summary", ""),
        }
    else:
        label = f"{chunk['source']} {chunk['section_no']} {chunk['title']}"
        metadata = {
            "chunk_id": chunk_id,
            "source_file": fname,
            "doc_type": doc_type,
            "doc_source": chunk["source"],
            "section_no": chunk["section_no"],
            "title": chunk["title"],
            "label": label,
            "original_text": chunk["text"],
            "context_summary": chunk.get("context_summary", ""),
        }

    return Document(page_content=page_content, metadata=metadata)


def load_chunks_as_documents(chunk_files=None, use_contextual=True) -> list[Document]:
    """processed/ 아래 청크 JSON들을 모두 읽어 Document 리스트로 반환.

    각 Document의 metadata["chunk_id"]는 항상 같은 순서(CHUNK_FILES 순서)로
    0부터 매겨지는 고유 ID. FAISS/BM25 두 인덱스가 같은 청크를 같은 ID로
    가리키게 해서, 나중에 하이브리드 검색에서 결과를 매칭시키는 데 쓴다.
    """
    if chunk_files is None:
        chunk_files = CONTEXTUAL_CHUNK_FILES if use_contextual else CHUNK_FILES
    documents: list[Document] = []
    chunk_id = 0

    for fname in chunk_files:
        path = PROCESSED_DIR / fname
        if not path.exists():
            print(f"경고: {path} 없음 (건너뜀)")
            continue
        raw_chunks = json.loads(path.read_text(encoding="utf-8"))
        for chunk in raw_chunks:
            documents.append(_to_document(chunk, fname, chunk_id))
            chunk_id += 1

    return documents


if __name__ == "__main__":
    docs = load_chunks_as_documents()
    print(f"총 {len(docs)}개 Document 로드\n")
    for d in docs:
        assert isinstance(d, Document)
        preview = d.page_content[:40].replace("\n", " ")
        print(f"[{d.metadata['doc_type']:>13}] {d.metadata['label'][:45]:<45} | {preview}...")

    types = {}
    for d in docs:
        types[d.metadata["doc_type"]] = types.get(d.metadata["doc_type"], 0) + 1
    print(f"\n문서 타입별 개수: {types}")
    print("검증: 실제 langchain_core.documents.Document 인스턴스 확인 완료")
