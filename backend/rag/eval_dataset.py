"""
핀버디 - RAG 평가셋 (12문항)
BCMD 세션1 방식 그대로: 정답이 우리 청크 문서에 실제로 있는지 먼저 검증하고,
이후 임베딩/검색 방식을 바꿀 때마다 이 12문항으로 점수를 매긴다.
"""

import json
import re
from pathlib import Path

CHUNK_FILES = [
    "chunks_isa_조세특례제한법91조18.json",
    "chunks_pension_소득세법59조3.json",
    "chunks_연금저축계좌_상품설명서.json",
    "chunks_외국인종합소득세신고안내.json",
]

EVAL = [
    # --- ISA 법조항 (조세특례제한법 91조의18) ---
    {"q": "ISA 비과세 한도금액은 얼마야? (총급여 5천만원 이하 기준)", "a": "400만원", "source": "isa"},
    {"q": "ISA 계좌의 계약기간은 최소 몇 년 이상이어야 해?", "a": "3년", "source": "isa"},
    {"q": "ISA 가입 가능한 최소 연령은?", "a": "19세", "source": "isa"},
    {"q": "ISA 총납입한도는 얼마야?", "a": "1억원", "source": "isa"},

    # --- 연금계좌 세액공제 (소득세법 59조의3, IRP+연금저축 공통) ---
    {"q": "종합소득금액 4천5백만원 이하인 경우 연금계좌 세액공제율은?", "a": "100분의 15", "source": "pension"},
    {"q": "연금저축계좌 세액공제 한도는 연간 얼마야?", "a": "600만원", "source": "pension"},
    {"q": "IRP와 연금저축 합산 세액공제 한도는 연간 얼마야?", "a": "900만원", "source": "pension"},

    # --- 연금저축계좌 상품설명서 (미래에셋) ---
    {"q": "연금저축계좌는 예금자보호법 적용을 받아?", "a": "보호되지 않습니다", "source": "product_guide"},
    {"q": "연금저축계좌 연금수령 요건은 몇 세 이후, 가입 몇 년 경과야?", "a": "55세 이후 및 가입기간 5년 경과", "source": "product_guide"},
    {"q": "연금저축계좌를 연금외수령하면 적용되는 세율은?", "a": "16.5%", "source": "product_guide"},

    # --- 외국인 종합소득세 신고안내 ---
    {"q": "외국인 거주자 종합소득세 신고 기간은?", "a": "5.1.부터 5.31.까지", "source": "tax_guide"},
    {"q": "외국인 세무 상담을 위한 영어전용 상담전화 번호는?", "a": "1588-0560", "source": "tax_guide"},
]


def norm(s: str) -> str:
    """표기 차이를 흡수: 공백/쉼표 제거"""
    return s.replace(" ", "").replace(",", "")


def load_all_text() -> str:
    """4개 청크 파일의 text 필드를 전부 이어붙여 하나의 문자열로 만든다."""
    combined = []
    for fname in CHUNK_FILES:
        path = Path(fname)
        if not path.exists():
            print(f"경고: {fname} 없음")
            continue
        chunks = json.loads(path.read_text(encoding="utf-8"))
        combined.extend(c["text"] for c in chunks)
    return "\n".join(combined)


if __name__ == "__main__":
    full_text = load_all_text()
    full_text_norm = norm(full_text)

    print(f"총 {len(EVAL)}문항 검증\n")
    found = 0
    for item in EVAL:
        ok = norm(item["a"]) in full_text_norm
        found += ok
        print(("O" if ok else "X"), f"[{item['source']:>13}] {item['a']:<20} <- {item['q']}")

    print(f"\n문서에서 확인된 정답: {found} / {len(EVAL)}")

    if found < len(EVAL):
        print("\n주의: 확인 안 된 문항은 표기 차이(예: '5.1.'vs'5월1일') 문제일 수 있음. 문항 조정 필요.")

    with open("eval/eval_12.json", "w", encoding="utf-8") as f:
        json.dump(EVAL, f, ensure_ascii=False, indent=2)
    print("\neval/eval_12.json 저장 완료")