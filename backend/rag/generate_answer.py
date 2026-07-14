"""
핀버디 - RAG 답변 생성 (검색된 청크 + LLM)

hybrid_search()로 찾은 top-k 청크를 컨텍스트로 넣고, OpenAI gpt-4o-mini에게
"이 문서 내용만 근거로 답하고, 문서에 없으면 모른다고 해" 라고 시켜서
실제 자연어 답변을 만든다.

역할 분리 재확인:
  - 임베딩(검색): BAAI/bge-m3 (로컬, 무료) — hybrid_search.py
  - 답변 생성(LLM): OpenAI gpt-4o-mini — 이 파일

주의: 투자상품 관련 질문이라도 "이 상품을 가입하세요/추천합니다" 같은 투자자문성
답변은 하지 않도록 시스템 프롬프트에서 명시적으로 제한한다 (기획서상 정책:
투자자문업 인가 문제로 개인 맞춤 종목 추천 금지, 카테고리 정보 제공까지만).
"""

import os
from pathlib import Path

from dotenv import load_dotenv
from openai import OpenAI

from hybrid_search import hybrid_search

RAG_DIR = Path(__file__).parent
LLM_MODEL = "gpt-4o-mini"

SYSTEM_PROMPT = """당신은 한국 거주 외국인을 위한 금융 정보 안내 챗봇 '핀버디'입니다.

[모드 분기 규정]
1. 일상 대화 / 인사 모드:
   - 사용자의 질문이 금융, 세무, 비자, 대출 등 금융 비즈니스와 전혀 무관한 일상적인 인사나 사소한 잡담(예: "안녕", "반가워", "너는 누구니?", "오늘 날씨 어때?")인 경우, 제공된 [문서] 내용을 참조하지 말고 친근하고 자연스럽게 핀버디 비서로서 일상 대화로 응답하세요. 이 모드에서는 답변 마지막에 참고 출처를 기재하지 마십시오.
2. 금융 전문 상담 모드:
   - 사용자의 질문이 금융 상품(ISA, IRP, 연금저축 등), 세금 신고, 해외 송금, 통장 개설, 비자 취업 활동 등 금융 제도와 관련된 것일 경우 아래 규칙을 엄격하게 준수하십시오.
     - 규칙 A: 반드시 [문서]에 주어진 내용만을 엄밀한 근거로 삼아 답변하십시오. 문서에 명시되지 않은 조건이나 금액 등은 임의로 추측하거나 상상해서 지어내지 마십시오. 만약 주어진 [문서] 컨텍스트에서 답을 찾을 수 없는 금융 질문이라면 반드시 "제공된 자료에서 관련 세부 사항을 확인할 수 없습니다"라고만 답변하십시오.
     - 규칙 B: 특정 금융상품에 대해 개인 맞춤으로 "가입을 권장합니다", "이 상품이 더 유리합니다" 등의 투자 자문이나 추천 발언은 절대 금지합니다. 제도 및 세법의 사실 관계 정보만 담아 답변하십시오.
     - 규칙 C: 답변 마무리에 참고한 문서의 출처(예: [출처: 조세특례제한법 제91조의18 ①항])를 반드시 대괄호 포맷으로 명시하십시오.
"""


def build_context(chunks) -> str:
    lines = []
    for doc, *_ in chunks:
        label = doc.metadata.get("label", "출처 미상")
        lines.append(f"[출처: {label}]\n{doc.page_content}")
    return "\n\n".join(lines)


def generate_answer(question: str, k: int = 3) -> dict:
    """질문에 대해 하이브리드 검색 + LLM 답변 생성을 한 번에 수행.

    반환: {"answer": str, "sources": [label, ...], "chunks": [...]}
    """
    hits = hybrid_search(question, k=k)
    context = build_context(hits)

    client = OpenAI()
    completion = client.chat.completions.create(
        model=LLM_MODEL,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": f"[문서]\n{context}\n\n[질문]\n{question}"},
        ],
        temperature=0.2,
    )
    answer = completion.choices[0].message.content

    # 답변 내용에 출처 표시가 존재하는 경우에만 RAG 매칭 처리로 간주하여 소스 뱃지 전달
    has_source = "[출처:" in answer
    sources_list = [doc.metadata.get("label", "") for doc, *_ in hits] if has_source else []
    chunks_list = [doc.page_content for doc, *_ in hits] if has_source else []

    return {
        "answer": answer,
        "sources": sources_list,
        "chunks": chunks_list,
    }


if __name__ == "__main__":
    load_dotenv(RAG_DIR / ".env")
    if not os.environ.get("OPENAI_API_KEY"):
        raise SystemExit("OPENAI_API_KEY가 없습니다. backend/rag/.env에 추가해주세요.")

    sample_questions = [
        "ISA 계좌 비과세 한도가 얼마야?",
        "외국인도 연금저축계좌 가입할 수 있어?",
    ]
    for q in sample_questions:
        print(f"\nQ: {q}")
        result = generate_answer(q)
        print(f"A: {result['answer']}")
        print(f"출처: {result['sources']}")
