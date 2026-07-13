# FinBuddy 작업 인계 문서 (다른 AI/세션에 그대로 붙여넣어서 이어가기용)

## 프로젝트 배경
iM금융그룹 개발경진대회(4회차) 출품작. 마감: 7/21 아이디어 기획서 제출.
한국 거주 외국인이 ISA/IRP/연금저축 같은 절세 금융제도를 모르거나 자격 확인이 어려운
문제를 해결하는 앱. 4탭 구조: 홈(정책피드) / 챗봇(RAG QA) / 자격진단 / 마이(프로필)
투자상품은 "추천"이 아니라 "정보제공"까지만 (투자자문업 인가 문제).

## 기술 스택 (확정)
- 임베딩(검색): **BAAI/bge-m3** (오픈소스, 로컬 실행, 무료, langchain-huggingface 통해 사용)
- LLM(답변생성): **OpenAI gpt-4o-mini**
- 리랭커: BAAI/bge-reranker-v2-m3 (아직 미구현, 로드맵상 다음 단계)
- 검색: FAISS(의미) + BM25(키워드, Kiwi 형태소분석기로 한국어 토큰화) 하이브리드, RRF로 결과 융합
- 백엔드: FastAPI
- 프론트엔드: **SwiftUI (iOS 네이티브)** — 사용자가 Swift만 할 줄 알아서 React Native 대신 선택

## 지금까지 완료한 것 (전부 검증됨)

### 1. RAG 파이프라인 (backend/rag/) — 완성, 로컬에서 실전 테스트까지 통과
- `load_chunks.py`: processed/의 4개 청크 JSON(26개 청크)을 langchain Document로 변환.
  각 청크에 고유 `chunk_id` 부여 (FAISS/BM25가 같은 청크를 같은 ID로 참조하기 위함)
- `build_index.py`: bge-m3로 임베딩 → FAISS 인덱스 생성/저장 (`faiss_index/`).
  임베딩 모델·인덱스는 모듈 전역 캐싱 처리(API 서버에서 매 요청마다 재로딩 안 하도록)
- `kiwi_tokenizer.py`: Kiwi 형태소분석 기반 토크나이저 (조사/어미 제거, 명사/숫자 등만 남김)
- `build_bm25_index.py`: BM25 인덱스 생성/저장 (`bm25_index/bm25.pkl`), 역시 캐싱 처리
- `hybrid_search.py`: FAISS+BM25를 RRF(Reciprocal Rank Fusion, k=60)로 융합해 top-k 반환
- `generate_answer.py`: hybrid_search 결과를 컨텍스트로 gpt-4o-mini에 넣어 실제 답변 생성.
  시스템 프롬프트에 "문서 근거만 사용", "투자자문성 답변 금지", "출처 표시" 규칙 명시
- `run_eval.py` / `run_eval_hybrid.py`: eval_12.json(12문항)으로 채점
  - **FAISS 단독: 11/12** (ISA 총납입한도 문항 실패 — 의미상 비슷한 다른 청크와 혼동)
  - **하이브리드(FAISS+BM25): 12/12 만점** (BM25 키워드 매칭이 그 문항을 잡아줌)

### 2. 자격진단 엔진 (backend/eligibility/eligibility_engine.py) — 기존에 완성돼 있던 것, 그대로 사용
ISA/IRP/연금저축펀드 3종 가입 가능 여부 판정. UserProfile 입력 → ProductResult 출력.

### 3. FastAPI 백엔드 (backend/api/main.py) — 완성, 로컬에서 정상 기동 확인
- `POST /eligibility/diagnose` — 실제 테스트 통과
- `POST /chat` — hybrid_search + generate_answer 연동 (bge-m3 의존이라 로컬 전용 테스트 필요, 아직 실제 앱에서 end-to-end 확인 전)
- `GET /health`
- 실행: `cd backend/api && source ../rag/venv/bin/activate && pip install -r requirements.txt && uvicorn main:app --reload --host 0.0.0.0 --port 8000`
- **방금 확인된 사실: 백엔드는 실행 중이고 정상 기동됨 (`http://0.0.0.0:8000`, "Application startup complete.")**

### 4. SwiftUI 프론트엔드 (frontend-ios/) — 코드 작성 완료, Xcode 프로젝트 연결 중
- Xcode 프로젝트 위치: `frontend-ios/FinBuddy/FinBuddy/FinBuddy.xcodeproj`
  (최신 Xcode의 "폴더 자동 동기화" 방식 — 소스 폴더에 파일만 넣으면 자동 인식됨)
- 실제 소스 폴더: `frontend-ios/FinBuddy/FinBuddy/FinBuddy/`
  - `FinBuddyApp.swift` — 4탭 TabView 진입점
  - `Models/Models.swift` — 요청/응답 모델 (ChatRequest/Response, EligibilityRequest/Response 등)
  - `Networking/APIClient.swift` — 백엔드 통신 (baseURL: `http://127.0.0.1:8000`, 시뮬레이터 기준)
  - `Views/HomeView.swift` — 정적 목업 (정책 피드)
  - `Views/ChatView.swift` — 실제 챗봇 연동 (ObservableObject 기반 ViewModel)
  - `Views/EligibilityView.swift` — 실제 자격진단 연동
  - `Views/MyPageView.swift` — 프로필/동의설정 (UserDefaults 기반, 정적)
  - `frontend-ios/FinBuddy/` (Xcode 프로젝트 폴더 밖의 원본 사본도 동일 파일로 유지 중 — 백업용, 수정 시 양쪽 다 반영 필요)
- Bundle ID: `comfinbuddy.dev.FinBuddy` (Info.plist에서 확인)
- Info.plist에 `App Transport Security Settings > Allow Arbitrary Loads = YES` 추가 완료 (로컬 HTTP 허용용)

## 방금 막 고친 버그 (직전 작업)
Xcode 최신 버전의 `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` 설정 때문에,
`import SwiftUI`만으로는 `ObservableObject`(Combine 프레임워크 소속)가 안 보이는 에러 발생:
```
Type 'ChatViewModel' does not conform to protocol 'ObservableObject'
Initializer 'init(wrappedValue:)' is not available due to missing import of defining module 'Combine'
```
**해결: `ChatView.swift`, `EligibilityView.swift` 양쪽 위치(Xcode 프로젝트 폴더 + frontend-ios/FinBuddy/ 원본)
모두에 `import Combine` 추가함.** 이 수정 직후 사용자가 다시 빌드하는 중이었음 — 결과 확인 안 된 상태.

## 지금 당장 다음에 해야 할 일 (우선순위 순)
1. **Xcode에서 ⌘R로 다시 빌드/실행해서 Combine 에러가 해결됐는지 확인** — 아직 미확인
2. 빌드 성공하면 시뮬레이터에서 4탭 다 뜨는지, 챗봇/자격진단 탭이 백엔드(`localhost:8000`, 이미 실행 중)와 실제로 통신되는지 확인
3. 에러 계속 나면: 에러 메시지 전체를 다시 보고 파일별로 고치기 (지금까지 패턴상 최신 Xcode의 strict concurrency/import visibility 설정 관련 이슈일 가능성 높음 — `import Combine`, `import Foundation` 등 명시적 import 누락이 원인일 수 있음)
4. 정상 동작 확인되면: 로드맵상 다음 단계는 Contextual Retrieval + Reranking(bge-reranker-v2-m3), 그리고 기획서 정리(마감 7/21)

## 알아둘 점 / 주의사항
- 백엔드는 사용자 로컬 macOS에서만 정상 동작 (bge-m3/torch, OpenAI API 둘 다 샌드박스에선 네트워크 차단으로 못 돌림 — 이건 참고용, 실제 작업 환경엔 해당 안 될 수 있음)
- `backend/rag/.env`에 `OPENAI_API_KEY` 있음 (사용자가 직접 넣음)
- venv는 `backend/rag/venv`에 있고, 백엔드(api)도 이 venv 재사용 중
- Xcode 프로젝트가 사용자 실수로 iOS가 아니라 macOS 타겟으로 설정되어 있었을 가능성 있었음 (Info 탭에서 "Custom macOS Application Target Properties"가 먼저 보였음) — 시뮬레이터가 iPhone으로 제대로 선택되어 있는지 다시 한번 확인 필요
