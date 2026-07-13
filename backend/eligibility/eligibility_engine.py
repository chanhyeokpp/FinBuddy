"""
이음뱅크 - 금융상품 자격진단 규칙엔진
ISA / IRP / 연금저축펀드 3종에 대한 외국인 거주자 자격 판정

입력값:
- is_resident: 거주자 여부 (183일 이상 국내 체류 또는 국내 주소 보유)
- age: 만 나이
- had_income_last_year: 직전연도 근로소득 유무 (15~19세 미만 ISA 예외 조건용)
- income_type: "근로소득자" | "자영업자" | "무소득"
- has_comprehensive_tax: 직전 3개 과세기간 중 금융소득종합과세 대상 여부

출력: 상품별 가능 여부 + 사유 + 필요서류
"""

from dataclasses import dataclass, field
from typing import Literal

IncomeType = Literal["근로소득자", "자영업자", "무소득"]


@dataclass
class UserProfile:
    is_resident: bool
    age: int
    had_income_last_year: bool
    income_type: IncomeType
    has_comprehensive_tax: bool = False  # 대부분 기본값 False


@dataclass
class ProductResult:
    eligible: bool
    reason: str
    required_docs: list = field(default_factory=list)


COMMON_DOCS = ["외국인등록증"]
RESIDENCY_DOCS = ["거소증", "출입국사실증명서"]


def check_isa(p: UserProfile) -> ProductResult:
    if not p.is_resident:
        return ProductResult(False, "국내 거주자(183일 이상 체류)만 가입 가능합니다.")

    age_ok = p.age >= 19 or (15 <= p.age < 19 and p.had_income_last_year)
    if not age_ok:
        return ProductResult(False, "만 19세 이상이거나, 만 15~19세 미만은 직전연도 근로소득이 있어야 합니다.")

    if p.has_comprehensive_tax:
        return ProductResult(False, "최근 3개 과세기간 중 금융소득종합과세 대상자는 가입이 제한됩니다.")

    docs = COMMON_DOCS + RESIDENCY_DOCS
    return ProductResult(True, "ISA 가입 요건을 충족합니다.", docs)


def check_irp(p: UserProfile) -> ProductResult:
    if not p.is_resident:
        return ProductResult(False, "국내 거주자만 가입 가능합니다.")

    if p.income_type not in ("근로소득자", "자영업자"):
        return ProductResult(False, "근로소득자 또는 자영업자만 가입 가능합니다.")

    docs = COMMON_DOCS + ["재직증명서 또는 근로계약서(자영업자는 사업자등록증)"]
    return ProductResult(True, "IRP 가입 요건을 충족합니다.", docs)


def check_pension_savings(p: UserProfile) -> ProductResult:
    if not p.is_resident:
        return ProductResult(False, "국내 거주자만 가입 가능합니다.")

    docs = COMMON_DOCS
    note = "가입은 가능하나, 종합소득이 없으면 세액공제 실익은 제한적입니다." \
        if p.income_type == "무소득" else "연금저축펀드 가입 요건을 충족합니다."
    return ProductResult(True, note, docs)


def diagnose(p: UserProfile) -> dict:
    return {
        "ISA": check_isa(p),
        "IRP": check_irp(p),
        "연금저축펀드": check_pension_savings(p),
    }


def print_report(p: UserProfile):
    results = diagnose(p)
    print(f"입력 프로필: 거주자={p.is_resident}, 나이={p.age}, 소득유형={p.income_type}")
    print("-" * 50)
    for name, r in results.items():
        status = "가능" if r.eligible else "불가"
        print(f"[{name}] {status} - {r.reason}")
        if r.required_docs:
            print(f"  필요서류: {', '.join(r.required_docs)}")
    print()


if __name__ == "__main__":
    # 테스트 케이스 3가지
    print("=== 케이스 1: F-2 비자, 거주자, 27세, 근로소득자 ===")
    print_report(UserProfile(is_resident=True, age=27, had_income_last_year=True, income_type="근로소득자"))

    print("=== 케이스 2: 입국 3개월차 (비거주자), 22세 ===")
    print_report(UserProfile(is_resident=False, age=22, had_income_last_year=False, income_type="무소득"))

    print("=== 케이스 3: 거주자, 17세, 직전연도 소득 없음 ===")
    print_report(UserProfile(is_resident=True, age=17, had_income_last_year=False, income_type="무소득"))