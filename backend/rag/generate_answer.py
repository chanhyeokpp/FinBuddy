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

규칙:
1. 반드시 [문서]에 주어진 내용만 근거로 답변하세요. 문서에 없는 내용은 추측하지 말고
   "제공된 자료에서 확인할 수 없습니다"라고 답하세요.
2. 특정 금융상품에 개인 맞춤으로 "가입하세요", "이게 유리합니다" 같은 투자자문성
   답변은 하지 마세요. 제도/조건에 대한 사실 정보 전달까지만 하세요.
3. 답변 마지막에 참고한 출처(법조항/문서명)를 간단히 표시하세요.
4. 외국인 사용자도 이해하기 쉽게 간결한 문장으로 답변하세요.
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

    return {
        "answer": answer,
        "sources": [doc.metadata.get("label", "") for doc, *_ in hits],
        "chunks": [doc.page_content for doc, *_ in hits],
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
