"""
이음뱅크(핀버디) - 법조항 청킹 스크립트
법조문을 항(①②③...) 단위로 분리하고, 각 청크에 요약 태그(메타데이터)를 붙여
임베딩 직전 단계의 JSON으로 만든다.

사용법: build_chunks()에 조문 원문 텍스트 + 항별 태그 매핑을 넣으면
        벡터DB에 넣기 좋은 형태(dict list)로 반환한다.
"""

import re
import json

# 항 번호로 쓰이는 원문자 ①~⑫
HANG_MARKERS = "①②③④⑤⑥⑦⑧⑨⑩⑪⑫"


def split_into_hang(article_text: str):
    """
    조문 원문을 항(①②③...) 단위로 분리.
    반환: [{"hang_no": "①", "text": "..."}, ...]
    분리 전 도입부(조 제목, 정의 등)는 hang_no="0"으로 따로 담음.
    """
    pattern = f"([{HANG_MARKERS}])"
    parts = re.split(pattern, article_text)

    chunks = []
    # parts[0]은 첫 항 마커 이전의 도입부
    intro = parts[0].strip()
    if intro:
        chunks.append({"hang_no": "0", "text": intro})

    # 이후는 [마커, 내용, 마커, 내용, ...] 형태로 옴
    for i in range(1, len(parts), 2):
        marker = parts[i]
        body = parts[i + 1].strip() if i + 1 < len(parts) else ""
        if body:
            chunks.append({"hang_no": marker, "text": f"{marker} {body}"})

    return chunks


def build_chunks(law_name: str, article_no: str, article_text: str, tag_map: dict):
    """
    law_name: 예) "조세특례제한법"
    article_no: 예) "제91조의18(개인종합자산관리계좌에 대한 과세특례)"
    tag_map: 항 번호 -> 요약 태그. 예) {"①": "ISA 가입자격", "②": "ISA 비과세한도"}
    """
    hang_chunks = split_into_hang(article_text)
    result = []
    for c in hang_chunks:
        tag = tag_map.get(c["hang_no"], "기타")
        result.append({
            "law": law_name,
            "article": article_no,
            "hang_no": c["hang_no"],
            "tag": tag,
            "text": c["text"],
        })
    return result


if __name__ == "__main__":
    # --- ISA 조항 테스트 (실제 업로드된 조세특례제한법 91조의18 원문 일부 사용) ---
    isa_text = """
① 다음 각 호의 어느 하나에 해당하는 거주자가 제3항 각 호의 요건을 모두 갖춘 계좌(이하 이 조에서 "개인종합자산관리계좌"라 한다)에 가입하거나 계약기간을 연장하는 경우 해당 계좌에서 발생하는 이자소득 및 배당소득의 합계액에 대해서는 제2항에 따른 비과세 한도금액까지는 소득세를 부과하지 아니한다.
1. 가입일 또는 연장일 기준 19세 이상인 자
2. 가입일 또는 연장일 기준 15세 이상인 자로서 가입일 또는 연장일이 속하는 과세기간의 직전 과세기간에 근로소득이 있는 자

② 개인종합자산관리계좌의 비과세 한도금액은 가입일 또는 연장일을 기준으로 다음 각 호의 구분에 따른 금액으로 한다.
1. 총급여액 5천만원 이하 등에 해당하는 경우: 400만원
2. 제1호에 해당하지 아니하는 자의 경우: 200만원

③ "개인종합자산관리계좌"란 다음 각 호의 요건을 모두 갖춘 계좌를 말한다.
1. 1명당 1개의 계좌만 보유할 것
4. 계약기간이 3년 이상일 것
5. 총납입한도가 1억원 이하이고, 연간 납입한도가 2천만원일 것

⑦ 신탁업자등은 개인종합자산관리계좌의 계좌보유자가 최초로 계약을 체결한 날부터 3년이 되는 날 전에 계약을 해지하는 경우(중도해지)에는 과세특례를 적용받은 소득세에 상당하는 세액을 추징하여야 한다.
"""

    isa_tag_map = {
        "0": "ISA 조항 개요",
        "①": "ISA 가입자격",
        "②": "ISA 비과세한도",
        "③": "ISA 계좌요건(1인1계좌·계약기간·납입한도)",
        "⑦": "ISA 중도해지 페널티",
    }

    chunks = build_chunks(
        law_name="조세특례제한법",
        article_no="제91조의18(개인종합자산관리계좌에 대한 과세특례)",
        article_text=isa_text,
        tag_map=isa_tag_map,
    )

    print(f"총 {len(chunks)}개 청크 생성\n")
    for c in chunks:
        preview = c["text"][:40].replace("\n", " ")
        print(f"[{c['tag']}] {preview}...")

    # 벡터DB 임베딩 직전 단계 JSON으로 저장
    with open("chunks_preview.json", "w", encoding="utf-8") as f:
        json.dump(chunks, f, ensure_ascii=False, indent=2)
    print("\nchunks_preview.json 저장 완료 (다음 단계: 임베딩)")
