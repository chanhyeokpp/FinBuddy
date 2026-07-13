"""
핀버디 - 백엔드 API 서버 (FastAPI)

두 도메인을 하나의 서버로 합침:
  1) /eligibility/diagnose - 자격진단 규칙엔진 (backend/eligibility/eligibility_engine.py)
  2) /chat - RAG 챗봇 (backend/rag/generate_answer.py: hybrid_search + gpt-4o-mini)

실행:
  cd backend/api
  pip install -r requirements.txt
  uvicorn main:app --reload --host 0.0.0.0 --port 8000

SwiftUI 앱(iOS 시뮬레이터)에서는 http://127.0.0.1:8000 으로 접속.
실기기 테스트 시에는 맥의 로컬 IP(예: http://192.168.x.x:8000)로 바꿔야 함.
"""

import sys
from pathlib import Path
from typing import Literal, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# backend/eligibility, backend/rag를 import 경로에 추가
BACKEND_DIR = Path(__file__).resolve().parent.parent
sys.path.append(str(BACKEND_DIR / "eligibility"))
sys.path.append(str(BACKEND_DIR / "rag"))

from eligibility_engine import UserProfile, diagnose  # noqa: E402

app = FastAPI(title="FinBuddy API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ---------- 자격진단 ----------

class EligibilityRequest(BaseModel):
    is_resident: bool
    age: int
    had_income_last_year: bool
    income_type: Literal["근로소득자", "자영업자", "무소득"]
    has_comprehensive_tax: bool = False


class ProductResultOut(BaseModel):
    eligible: bool
    reason: str
    required_docs: list[str]


class EligibilityResponse(BaseModel):
    ISA: ProductResultOut
    IRP: ProductResultOut
    연금저축펀드: ProductResultOut


@app.post("/eligibility/diagnose", response_model=EligibilityResponse)
def eligibility_diagnose(req: EligibilityRequest):
    profile = UserProfile(
        is_resident=req.is_resident,
        age=req.age,
        had_income_last_year=req.had_income_last_year,
        income_type=req.income_type,
        has_comprehensive_tax=req.has_comprehensive_tax,
    )
    result = diagnose(profile)
    return {
        name: ProductResultOut(
            eligible=r.eligible, reason=r.reason, required_docs=r.required_docs
        )
        for name, r in result.items()
    }


# ---------- 챗봇 (RAG) ----------

class ChatRequest(BaseModel):
    question: str


class ChatResponse(BaseModel):
    answer: str
    sources: list[str]


@app.post("/chat", response_model=ChatResponse)
def chat(req: ChatRequest):
    if not req.question.strip():
        raise HTTPException(status_code=400, detail="question이 비어있습니다.")

    # 무거운 임베딩 모델(bge-m3)은 실제로 호출될 때만 로드되도록 지연 import
    from dotenv import load_dotenv
    load_dotenv(BACKEND_DIR / "rag" / ".env")
    from generate_answer import generate_answer

    result = generate_answer(req.question)
    return {"answer": result["answer"], "sources": result["sources"]}


# ---------- 여신보조리포트 ----------

class UserBehaviorData(BaseModel):
    search_queries: list[str]
    clicked_policies: list[str]
    chat_count: int


class LoanReportRequest(BaseModel):
    profile: EligibilityRequest
    behavior: UserBehaviorData


class LoanReportResponse(BaseModel):
    summary: str
    recommended_product: str
    credit_score_estimate: str
    banker_notes: str


@app.post("/loan/report", response_model=LoanReportResponse)
def generate_loan_report(req: LoanReportRequest):
    import os
    from openai import OpenAI
    from dotenv import load_dotenv
    load_dotenv(BACKEND_DIR / "rag" / ".env")
    
    if not os.environ.get("OPENAI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY가 설정되어 있지 않습니다.")
        
    client = OpenAI()
    
    prompt = f"""당신은 은행 여신(대출) 심사역을 돕는 AI 신용평가 에이전트입니다.
사용자의 프로필 정보와 금융 활동 로그 데이터를 바탕으로, 해당 외국인 고객의 신용 상태 및 가치 평가 요약 리포트를 격식 있는 한국어로 작성해 주세요.

[사용자 프로필]
- 거주 여부: {"국내 거주자 (183일 이상 체류)" if req.profile.is_resident else "비거주자"}
- 나이: 만 {req.profile.age}세
- 직전연도 소득 유무: {"있음" if req.profile.had_income_last_year else "없음"}
- 소득 유형: {req.profile.income_type}
- 금융소득종합과세 대상 여부: {"대상자" if req.profile.has_comprehensive_tax else "비대상자"}

[앱 내 활동 행동 데이터]
- 검색한 금융 키워드: {", ".join(req.behavior.search_queries) if req.behavior.search_queries else "없음"}
- 조회/클릭한 정책 피드: {", ".join(req.behavior.clicked_policies) if req.behavior.clicked_policies else "없음"}
- 챗봇 상담 횟수: {req.behavior.chat_count}회

[출력 포맷 요구사항 JSON]
반드시 다음 Key를 가지는 JSON 형식으로만 응답해 주세요. 다른 서론이나 설명은 포함하지 마세요.
1. "summary": 사용자의 소득 안정성, 연령대, 한국 내 금융 활동 열의(행동 데이터 참고)를 토대로 신용도를 2-3문장으로 종합 요약한 텍스트.
2. "recommended_product": 외국인 직장인/자영업자에게 적합한 서민금융 대출 상품 또는 절세 저축 연계 여신 상품 추천 (예: 'iM 새희망홀씨 대출', '외국인 근로자 전세자금대출' 등 어조에 맞게 기재).
3. "credit_score_estimate": 추정 등급 (예: '우수 (A등급)', '일반 (B등급)', '신규/미평가' 등 프로필 근거 추정).
4. "banker_notes": 창구 행원이 참고할 수 있는 비공개 메모 및 상담 팁 (예: '거주 및 근로 형태 확인용 외국인등록증 증빙 필요', '금융 활동 이력이 활발하므로 ISA 개설 연계 추천' 등).

응답 예시:
{{
  "summary": "...",
  "recommended_product": "...",
  "credit_score_estimate": "...",
  "banker_notes": "..."
}}
"""
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        response_text = completion.choices[0].message.content
        import json
        data = json.loads(response_text)
        return LoanReportResponse(
            summary=data.get("summary", ""),
            recommended_product=data.get("recommended_product", ""),
            credit_score_estimate=data.get("credit_score_estimate", ""),
            banker_notes=data.get("banker_notes", "")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"리포트 생성 중 오류가 발생했습니다: {str(e)}")


# ---------- 행원용 모바일 HTML 웹 리포트 및 용어 번역 ----------
from fastapi.responses import HTMLResponse

class JargonRequest(BaseModel):
    word: str

class JargonResponse(BaseModel):
    word: str
    translation_en: str
    translation_zh: str
    translation_vi: str
    simple_definition: str


@app.post("/api/jargon", response_model=JargonResponse)
def get_jargon_info(req: JargonRequest):
    import os
    from openai import OpenAI
    from dotenv import load_dotenv
    load_dotenv(BACKEND_DIR / "rag" / ".env")
    
    if not os.environ.get("OPENAI_API_KEY"):
        raise HTTPException(status_code=500, detail="OPENAI_API_KEY가 설정되어 있지 않습니다.")
        
    client = OpenAI()
    
    prompt = f"""당신은 한국 금융 용어를 모르는 외국인 초보자를 돕는 번역기 에이전트입니다.
다음 한국어 금융 단어에 대해 아래 4개 정보를 채워서 JSON으로 응답해 주세요.

대상 단어: "{req.word}"

[요구사항 JSON Key]
1. "translation_en": 해당 용어의 영어 번역어 (예: "Tax-free" or "Income Tax Return")
2. "translation_zh": 해당 용어의 중국어 번역어 (예: "免税" or "综合所得税")
3. "translation_vi": 해당 용어의 베트남어 번역어 (예: "Miễn thuế" or "Khai thuế thu nhập tổng hợp")
4. "simple_definition": 외국인 초보자가 한눈에 이해할 수 있게 한자어를 사용하지 않고 1문장으로 쉽게 비유/설명한 한국어 한 줄 해설 (예: "세금을 내지 않고 이자나 이익을 전부 다 가져갈 수 있는 혜택이에요").

응답 예시:
{{
  "translation_en": "...",
  "translation_zh": "...",
  "translation_vi": "...",
  "simple_definition": "..."
}}
"""
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
            response_format={"type": "json_object"}
        )
        import json
        data = json.loads(completion.choices[0].message.content)
        return JargonResponse(
            word=req.word,
            translation_en=data.get("translation_en", ""),
            translation_zh=data.get("translation_zh", ""),
            translation_vi=data.get("translation_vi", ""),
            simple_definition=data.get("simple_definition", "")
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"용어 사전 검색 오류: {str(e)}")


@app.get("/banker/report", response_class=HTMLResponse)
def get_banker_report_html(
    is_resident: bool = True,
    age: int = 27,
    had_income_last_year: bool = True,
    income_type: str = "근로소득자",
    has_comprehensive_tax: bool = False,
    search_queries: str = "",
    clicked_policies: str = "",
    chat_count: int = 3
):
    import os
    from openai import OpenAI
    from dotenv import load_dotenv
    load_dotenv(BACKEND_DIR / "rag" / ".env")
    
    if not os.environ.get("OPENAI_API_KEY"):
        return """<html><body><h3>Error: OPENAI_API_KEY가 설정되어 있지 않습니다.</h3></body></html>"""
        
    client = OpenAI()
    
    search_list = [s.strip() for s in search_queries.split(",") if s.strip()]
    clicked_list = [c.strip() for c in clicked_policies.split(",") if c.strip()]
    
    prompt = f"""당신은 은행 여신(대출) 심사역을 돕는 AI 신용평가 에이전트입니다.
사용자의 프로필 정보와 금융 활동 로그 데이터를 바탕으로, 해당 외국인 고객의 신용 상태 및 가치 평가 요약 리포트를 격식 있는 한국어로 작성해 주세요.

[사용자 프로필]
- 거주 여부: {"국내 거주자 (183일 이상 체류)" if is_resident else "비거주자"}
- 나이: 만 {age}세
- 직전연도 소득 유무: {"있음" if had_income_last_year else "없음"}
- 소득 유형: {income_type}
- 금융소득종합과세 대상 여부: {"대상자" if has_comprehensive_tax else "비대상자"}

[앱 내 활동 행동 데이터]
- 검색한 금융 키워드: {", ".join(search_list) if search_list else "없음"}
- 조회/클릭한 정책 피드: {", ".join(clicked_list) if clicked_list else "없음"}
- 챗봇 상담 횟수: {chat_count}회

[출력 포맷 요구사항 JSON]
반드시 다음 Key를 가지는 JSON 형식으로만 응답해 주세요. 다른 서론이나 설명은 포함하지 마세요.
1. "summary": 사용자의 소득 안정성, 연령대, 한국 내 금융 활동 열의(행동 데이터 참고)를 토대로 신용도를 2-3문장으로 종합 요약한 텍스트.
2. "recommended_product": 외국인 직장인/자영업자에게 적합한 서민금융 대출 상품 또는 절세 저축 연계 여신 상품 추천 (예: 'iM 새희망홀씨 대출', '외국인 근로자 전세자금대출' 등 어조에 맞게 기재).
3. "credit_score_estimate": 추정 등급 (예: '우수 (A등급)', '일반 (B등급)', '신규/미평가' 등 프로필 근거 추정).
4. "banker_notes": 창구 행원이 참고할 수 있는 비공개 메모 및 상담 팁 (예: '거주 및 근로 형태 확인용 외국인등록증 증빙 필요', '금융 활동 이력이 활발하므로 ISA 개설 연계 추천' 등).
"""
    try:
        completion = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.3,
            response_format={"type": "json_object"}
        )
        import json
        data = json.loads(completion.choices[0].message.content)
    except Exception as e:
        data = {
            "summary": "서버 통신 장애로 요약을 일시적으로 가져올 수 없습니다.",
            "recommended_product": "iM 새희망홀씨 대출 (기본 상품 추천)",
            "credit_score_estimate": "등급 미평가 (오류)",
            "banker_notes": f"에러 로그: {str(e)}"
        }

    html_content = f"""
    <!DOCTYPE html>
    <html lang="ko">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>iM뱅크 행원 보조용 AI 신용진단 리포트</title>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700&display=swap" rel="stylesheet">
        <style>
            body {{
                font-family: 'Inter', sans-serif;
                background: linear-gradient(135deg, #00d2ff 0%, #3a7bd5 100%);
                color: #333;
                margin: 0;
                padding: 16px;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }}
            .card {{
                background: rgba(255, 255, 255, 0.85);
                backdrop-filter: blur(12px);
                -webkit-backdrop-filter: blur(12px);
                border-radius: 20px;
                border: 1px solid rgba(255, 255, 255, 0.4);
                box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.15);
                padding: 24px;
                max-width: 480px;
                width: 100%;
                box-sizing: border-box;
            }}
            .header {{
                text-align: center;
                margin-bottom: 24px;
            }}
            .logo {{
                font-size: 22px;
                font-weight: 700;
                color: #008f85;
                background: linear-gradient(to right, #00D8B2, #A6E01A);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                margin-bottom: 4px;
            }}
            .title {{
                font-size: 16px;
                color: #666;
                margin: 0;
            }}
            h2 {{
                font-size: 18px;
                border-left: 4px solid #00D8B2;
                padding-left: 8px;
                margin: 20px 0 10px 0;
                color: #222;
            }}
            .profile-grid {{
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 8px;
                background: rgba(0, 0, 0, 0.03);
                padding: 12px;
                border-radius: 12px;
                font-size: 14px;
            }}
            .profile-item {{
                margin-bottom: 4px;
            }}
            .label {{
                font-weight: 600;
                color: #666;
            }}
            .value {{
                color: #111;
            }}
            .badge {{
                display: inline-block;
                background: rgba(0, 216, 178, 0.15);
                color: #008f85;
                padding: 4px 10px;
                border-radius: 6px;
                font-size: 14px;
                font-weight: 700;
            }}
            .summary, .notes {{
                font-size: 14px;
                line-height: 1.6;
                color: #444;
            }}
            .footer {{
                text-align: center;
                margin-top: 24px;
                font-size: 11px;
                color: #888;
            }}
        </style>
    </head>
    <body>
        <div class="card">
            <div class="header">
                <div class="logo">iM FinBuddy</div>
                <div class="title">행원 상담 보조용 AI 신용진단 리포트</div>
            </div>
            
            <h2>고객 기본 프로필</h2>
            <div class="profile-grid">
                <div class="profile-item"><span class="label">나이:</span> <span class="value">만 {age}세</span></div>
                <div class="profile-item"><span class="label">거주 여부:</span> <span class="value">{"국내 거주" if is_resident else "해외/미인증"}</span></div>
                <div class="profile-item"><span class="label">소득원:</span> <span class="value">{income_type}</span></div>
                <div class="profile-item"><span class="label">종합과세:</span> <span class="value">{"대상" if has_comprehensive_tax else "해당없음"}</span></div>
            </div>
            
            <h2>AI 종합평가 요약</h2>
            <div class="summary">
                {data.get("summary", "")}
            </div>
            
            <h2>추천 여신 상품</h2>
            <div>
                <span class="badge">{data.get("recommended_product", "")}</span>
            </div>
            
            <h2>추정 신용 수준</h2>
            <div>
                <strong>{data.get("credit_score_estimate", "")}</strong>
            </div>
            
            <h2>창구 행원 참고사항 (상담 팁)</h2>
            <div class="notes">
                {data.get("banker_notes", "")}
            </div>
            
            <div class="footer">
                본 리포트는 고객 동의하에 앱 내 활동 로그를 기반으로 임시 자동 생성된 심사 보조용 자료입니다. (iM금융그룹)
            </div>
        </div>
    </body>
    </html>
    """
    return HTMLResponse(content=html_content, status_code=200)


@app.get("/health")
def health():
    return {"status": "ok"}
