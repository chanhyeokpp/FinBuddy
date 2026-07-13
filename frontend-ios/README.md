# FinBuddy iOS 프로토타입 - 설치 가이드

이 폴더의 .swift 파일들은 완성된 코드지만, Xcode 프로젝트 자체(.xcodeproj)는
Xcode GUI로만 만들 수 있어서 미리 준비해두지 못했다. 아래 순서대로 5분이면 연결된다.

## 1) Xcode 새 프로젝트 생성

1. Xcode 실행 → "Create New Project"
2. iOS → App 선택
3. Product Name: `FinBuddy`
4. Interface: **SwiftUI**, Language: **Swift**
5. 저장 위치: 아무 곳 (예: 이 저장소 바깥의 아무 폴더). 나중에 파일만 옮겨 담을 것

## 2) 이 폴더의 파일들을 프로젝트에 추가

Xcode 프로젝트 생성 후 기본으로 생기는 `ContentView.swift`, `FinBuddyApp.swift`는
삭제하고, 이 `frontend-ios/FinBuddy/` 안의 모든 .swift 파일을 Xcode 프로젝트
네비게이터로 드래그 앤 드롭 (반드시 "Copy items if needed" 체크, target은 FinBuddy 체크)

## 3) 로컬 네트워크 허용 (Info.plist)

시뮬레이터에서 `http://127.0.0.1:8000`(백엔드) 호출을 허용하려면 Info 설정에
아래 내용 추가 필요:
- 프로젝트 설정 → Info 탭 → "Custom iOS Target Properties"에 우클릭 → Add Row
- Key: `App Transport Security Settings` (Dictionary)
  - 하위에 `Allow Arbitrary Loads` = YES (Boolean)

(프로토타입 단계라 가장 간단한 방법을 씀. 실제 배포 시엔 HTTPS로 교체 필요)

## 4) 백엔드 먼저 실행

```
cd backend/api
source ../rag/venv/bin/activate   # 기존에 만든 venv 재사용 가능 (rag 쪽 패키지 이미 있음)
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 5) Xcode에서 빌드 & 실행

시뮬레이터 선택 (예: iPhone 16) → ▶ Run

4개 탭(홈/챗봇/자격진단/마이)이 뜨고, 챗봇/자격진단 탭은 실제 백엔드와 통신한다.
