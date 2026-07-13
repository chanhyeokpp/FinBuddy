"""
핀버디 - 한국어 형태소분석 기반 토크나이저 (BM25용)

BM25는 원래 띄어쓰기 기준으로 단어를 쪼개는데, 한국어는 조사(가/는/를/에서...)가
단어에 그대로 붙어 있어서 그렇게 하면 "총납입한도가"와 "총납입한도는"이 서로
다른 단어로 인식돼버려 검색이 안 된다.

Kiwi(형태소분석기)로 문장을 형태소 단위로 쪼갠 뒤, 조사(J*)/어미(E*)/문장부호(S*)처럼
검색에 도움이 안 되는 순수 문법 형태소는 제거하고, 명사·동사·숫자·외국어 등
"의미를 담고 있는" 형태소만 남긴다.
"""

from kiwipiepy import Kiwi

# 검색에 도움이 안 되는 순수 문법 형태소 태그 (조사/어미/문장부호)
STOP_TAGS = {
    "JKS", "JKC", "JKG", "JKO", "JKB", "JKV", "JKQ", "JX", "JC",  # 조사
    "EP", "EF", "EC", "ETN", "ETM",  # 어미
    "SF", "SP", "SS", "SE", "SO", "SW",  # 문장부호/기호
}

_kiwi = Kiwi()


def tokenize_ko(text: str) -> list[str]:
    """텍스트를 BM25 인덱싱용 토큰 리스트로 변환.

    예) "ISA 총납입한도는 얼마야?" -> ["ISA", "총", "납입", "한도", "이", "얼마", "야"]
    (조사 "는", 물음표 등은 제거됨)
    """
    tokens = _kiwi.tokenize(text)
    return [t.form for t in tokens if t.tag not in STOP_TAGS]


if __name__ == "__main__":
    samples = [
        "ISA 총납입한도는 얼마야?",
        "연금저축계좌 세액공제 한도는 연간 얼마야?",
        "① 다음 각 호의 어느 하나에 해당하는 거주자가",
    ]
    for s in samples:
        print(f"{s}\n  -> {tokenize_ko(s)}\n")
