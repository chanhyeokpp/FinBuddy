"""
핀버디 - PDF 상품설명서 청킹 스크립트
법조항(law_chunker.py)과 달리, 이런 PDF는 "1. 제목" 형태의 섹션 번호로 구성되어 있어
섹션 단위로 분리한다. 섹션이 길면(예: 500자 초과) 문단 단위로 한 번 더 쪼갠다.
"""

import re
import json

SECTION_PATTERN = re.compile(r"^(\d+)\.\s*(.+)$", re.MULTILINE)
MAX_CHUNK_LEN = 500  # 이 길이 넘으면 문단 단위로 추가 분할


def split_into_sections(doc_text: str):
    """
    '1. 상품 개요 및 특징' 같은 섹션 헤더 기준으로 텍스트를 나눈다.
    반환: [{"section_no": "1", "title": "...", "text": "..."}]
    """
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
    """섹션이 너무 길면 문단(빈 줄) 기준으로 추가 분할."""
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


if __name__ == "__main__":
    # 실제 미래에셋 연금저축계좌 설명서 발췌본으로 테스트
    doc_text = """
1. 상품 개요 및 특징
상품명: 연금저축계좌(신) - 2013년 3월 이후 당사에서 신규 개설된 계좌
상품특징: 소득세법에서 정한 연금수령요건에 따라 자금을 인출하는 경우, 연금소득으로 저율과세되는 상품으로, 연간 세액공제 혜택까지 받을 수 있는 세제혜택 금융상품

2. 연금저축계좌 가입 및 납입
계좌종류: [연금저축펀드] 자본시장법에 따른 투자중개업자와 체결하는 집합투자증권 중개계약
가입대상: 제한 없음
납입한도: 연간 1,800만원 + ISA 만기계좌의 전환 금액
세액공제: 연간 600만원 한도, ISA 만기 전환금액 있는 경우 최대 연간 900만원 한도 공제
총급여액 5.5천만원 이하는 공제율 16.5%, 초과는 13.2%

3. 연금저축계좌 운용 및 이체
운용방법: 가입자는 계좌 내에서 다양한 펀드를 금융상황 변동에 따라 자유롭게 선택하여 투자 가능
계좌이체: 서로 다른 종류(신탁, 펀드, 보험)간의 이체도 가능하며, 세액공제나 과세이연 혜택을 유지

4. 연금 수령 및 인출
연금수령 요건: 55세 이후 및 가입기간 5년 경과
연금수령한도: 매년 연금수령한도(세전금액) 이내에서 인출을 의미하며, 한도를 초과하는 금액은 연금외수령에 해당

5. 적용세제
연금저축계좌를 연금외수령하는 경우, 연금수령 대비 고율의 과세가 적용됩니다.
연금수령: 과세대상소득은 연금소득세(3.3%~5.5%) 적용, 만70세 미만 5.5%, 만80세 이상 3.3%
연금외수령: 과세대상소득은 기타소득세 16.5% 적용

6. 가입자 유의사항
연금저축계좌는 예금자보호법에 따라 보호되지 않습니다.
연금저축계좌는 연금수령 이외의 방법(중도해지 포함)으로 인출 시, 기타소득세가 부과되어 세제상 불이익을 받을 수 있습니다.

7. 고객 권익보호 사항
문의사항이나 추가 상담을 원하시면, 영업점 및 고객센터(1588-6800)를 통해 문의하시기 바라며
"""

    chunks = build_chunks("연금저축계좌_핵심설명서(미래에셋)", doc_text)

    print(f"총 {len(chunks)}개 청크 생성\n")
    for c in chunks:
        preview = c["text"][:35].replace("\n", " ")
        print(f"[{c['section_no']}] {c['title']} - {preview}...")

    with open("pdf_chunks_preview.json", "w", encoding="utf-8") as f:
        json.dump(chunks, f, ensure_ascii=False, indent=2)
    print("\npdf_chunks_preview.json 저장 완료")
