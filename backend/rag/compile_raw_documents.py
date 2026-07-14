import re
import json
from pathlib import Path

# pdf_chunker.py 와 동일한 청킹 알고리즘 적용
SECTION_PATTERN = re.compile(r"^(\d+)\.\s*(.+)$", re.MULTILINE)
MAX_CHUNK_LEN = 500

def split_into_sections(doc_text: str):
    matches = list(SECTION_PATTERN.finditer(doc_text))
    sections = []
    for i, m in enumerate(matches):
        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(doc_text)
        sections.append({
            "section_no": m.group(1),
            "title": m.group(2).strip(),
            "text": doc_text[start:end].strip(),
        })
    return sections

def split_long_section(section: dict, max_len=MAX_CHUNK_LEN):
    text = section["text"]
    if len(text) <= max_len:
        return [section]

    paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
    result = []
    for idx, p in enumerate(paragraphs, 1):
        result.append({
            "section_no": f"{section['section_no']}-{idx}",
            "title": section["title"],
            "text": p,
        })
    return result

def build_chunks(doc_name: str, doc_text: str):
    sections = split_into_sections(doc_text)
    chunks = []
    for s in sections:
        for sub in split_long_section(s):
            chunks.append({
                "source": doc_name,
                "section_no": sub["section_no"],
                "title": sub["title"],
                "text": sub["text"],
            })
    return chunks

def main():
    RAG_DIR = Path(__file__).resolve().parent
    DOCS_DIR = RAG_DIR.parent.parent / "docs"
    PROCESSED_DIR = RAG_DIR / "processed"
    PROCESSED_DIR.mkdir(exist_ok=True)
    
    # 5종의 신규 문서 파싱 매핑
    NEW_DOCUMENTS = [
        {
            "src": DOCS_DIR / "product_guides" / "irp_설명서.txt",
            "dest": PROCESSED_DIR / "chunks_irp_상품설명서.json",
            "name": "개인형퇴직연금(IRP)_상품설명서"
        },
        {
            "src": DOCS_DIR / "tax_guides" / "외국인_통장개설_가이드.txt",
            "dest": PROCESSED_DIR / "chunks_외국인_통장개설_가이드.json",
            "name": "외국인_통장개설_가이드"
        },
        {
            "src": DOCS_DIR / "tax_guides" / "외국인_해외송금_가이드.txt",
            "dest": PROCESSED_DIR / "chunks_외국인_해외송금_가이드.json",
            "name": "외국인_해외송금_가이드"
        },
        {
            "src": DOCS_DIR / "tax_guides" / "외국인_비자_취업_가이드.txt",
            "dest": PROCESSED_DIR / "chunks_외국인_비자_취업_가이드.json",
            "name": "외국인_비자_취업_가이드"
        },
        {
            "src": DOCS_DIR / "product_guides" / "imbank_외국인_혜택.txt",
            "dest": PROCESSED_DIR / "chunks_imbank_외국인_혜택.json",
            "name": "iM뱅크_외국인_혜택"
        }
    ]

    for doc in NEW_DOCUMENTS:
        src_path = doc["src"]
        dest_path = doc["dest"]
        if not src_path.exists():
            print(f"소스 파일 없음: {src_path}")
            continue
            
        print(f"컴파일 중: {src_path.name}...")
        with open(src_path, "r", encoding="utf-8") as f:
            text = f.read()
            
        chunks = build_chunks(doc["name"], text)
        with open(dest_path, "w", encoding="utf-8") as f:
            json.dump(chunks, f, ensure_ascii=False, indent=2)
            
        print(f"  -> {len(chunks)}개 청크 저장 완료: {dest_path.name}")

if __name__ == "__main__":
    main()
