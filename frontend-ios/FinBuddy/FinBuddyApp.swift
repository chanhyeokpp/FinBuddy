import SwiftUI
import Combine

/// 앱 전체의 탭 탐색, 챗봇 질문 프리필, 자격진단 상태 로컬 캐싱 등을 공유하기 위한 AppState
class AppState: ObservableObject {
    @Published var selectedTab: Int = 0 // 0: 홈, 1: 챗봇, 2: 자격진단, 3: 마이
    
    // 챗봇 자동 질문 연동용
    @Published var chatPrefillQuestion: String = ""
    @Published var shouldAutoSend: Bool = false
    
    // 자격진단 완료 여부 및 결과 객체 로컬 캐시
    @Published var isDiagnosed: Bool = false
    @Published var diagnosedResult: EligibilityResponse? = nil
    
    init() {
        // UserDefaults에서 기존 완료 데이터 복구
        self.isDiagnosed = UserDefaults.standard.bool(forKey: "is_eligibility_diagnosed")
        if let data = UserDefaults.standard.data(forKey: "eligibility_result_json"),
           let decoded = try? JSONDecoder().decode(EligibilityResponse.self, from: data) {
            self.diagnosedResult = decoded
        }
    }
    
    func saveDiagnosisResult(response: EligibilityResponse) {
        self.isDiagnosed = true
        self.diagnosedResult = response
        UserDefaults.standard.set(true, forKey: "is_eligibility_diagnosed")
        if let encoded = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(encoded, forKey: "eligibility_result_json")
        }
    }
    
    func clearDiagnosis() {
        self.isDiagnosed = false
        self.diagnosedResult = nil
        UserDefaults.standard.set(false, forKey: "is_eligibility_diagnosed")
        UserDefaults.standard.removeObject(forKey: "eligibility_result_json")
    }
    
    var diagnosisSummary: String {
        guard let res = diagnosedResult else { return "" }
        var eligibleProducts: [String] = []
        if res.ISA.eligible { eligibleProducts.append("ISA") }
        if res.IRP.eligible { eligibleProducts.append("IRP") }
        if res.연금저축펀드.eligible { eligibleProducts.append("연금저축") }
        
        if eligibleProducts.isEmpty {
            return "가입 가능한 절세 상품 없음"
        } else {
            return "\(eligibleProducts.joined(separator: ", ")) 가입 가능"
        }
    }
}

@main
struct FinBuddyApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(appState)
        }
    }
}

struct RootTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem { Label("홈", systemImage: "house.fill") }
                .tag(0)

            ChatView()
                .tabItem { Label("챗봇", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(1)

            EligibilityView()
                .tabItem { Label("자격진단", systemImage: "checkmark.seal.fill") }
                .tag(2)

            MyPageView()
                .tabItem { Label("마이", systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.imMint) // 선택된 탭 아이템 색상을 iM뱅크 브랜드 민트색으로 변경
    }
}
