import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var appState: AppState
    
    // 로컬 UserDefaults 저장 프로퍼티
    @AppStorage("fb_nickname") private var nickname: String = ""
    @AppStorage("fb_marketing_consent") private var marketingConsent: Bool = false
    @AppStorage("fb_data_consent") private var dataConsent: Bool = true

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                    
                    // 1. 자격진단 결과 요약 대시보드 카드 (프로필 최상단에 노출)
                    diagnosisSummaryCard
                        .padding(.horizontal)
                    
                    // 2. 프로필 입력 카드 (Toss 스타일 글래스 카드화)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("프로필 설정")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Divider()
                        
                        TextField("닉네임 입력 (예: 홍길동)", text: $nickname)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        
                        // 닉네임 용도 및 수집 범위 가이드 설명 문구 추가
                        Text("💡 입력하신 닉네임은 챗봇 답변과 홈 화면의 맞춤 금융 피드 안내 시에만 사용됩니다. 외부 서버로 전송되거나 타인에게 노출되지 않으니 자유롭게 입력하셔도 안전합니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(18)
                    .glassmorphicCard()
                    .padding(.horizontal)
                    
                    // 3. 마케팅 및 정보수집 동의 설정 카드
                    VStack(alignment: .leading, spacing: 18) {
                        Text("동의 설정")
                            .font(.headline.bold())
                            .foregroundStyle(.primary)
                        
                        Divider()
                        
                        Toggle("맞춤 정책/이벤트 알림 수신 동의", isOn: $marketingConsent)
                            .tint(.imMint)
                        
                        Toggle("자격진단 데이터 저장 동의 (필수)", isOn: $dataConsent)
                            .tint(.imMint)
                    }
                    .padding(18)
                    .glassmorphicCard()
                    .padding(.horizontal)
                    
                    // 4. 정보안내 및 법적 면책 고지 카드
                    VStack(alignment: .leading, spacing: 12) {
                        Text("⚠️ 안내 및 면책 고지")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        Text("핀버디는 투자자문업자가 아니며, 특정 금융상품을 권유 및 추천하지 않습니다. 본 앱에서 제공하는 진단 결과와 챗봇의 정보는 세제 혜택 가이드를 돕기 위한 사실 정보이며, 최종 가입 의사 결정 전 반드시 해당 취급 금융기관의 공식 안내서를 필독하시기 바랍니다.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(16)
                    .glassmorphicCard()
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            }
            .navigationTitle("마이")
        }
    }
    
    // 자격진단 결과 요약 대시보드 컴포넌트
    private var diagnosisSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("나의 금융 자격 현황")
                .font(.headline.bold())
                .foregroundStyle(.primary)
            
            Divider()
            
            if appState.isDiagnosed, let result = appState.diagnosedResult {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        ForEach(result.all, id: \.name) { item in
                            let name = item.name == "연금저축펀드" ? "연금저축" : item.name
                            let eligible = item.result.eligible
                            
                            HStack(spacing: 4) {
                                Image(systemName: eligible ? "checkmark.circle.fill" : "xmark.circle")
                                    .font(.caption)
                                Text(name)
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(eligible ? Color.imMint : .gray)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(eligible ? Color.imMint.opacity(0.1) : Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button {
                        withAnimation {
                            appState.clearDiagnosis()
                        }
                    } label: {
                        Text("진단 내역 초기화")
                            .font(.caption2.bold())
                            .foregroundStyle(.red)
                    }
                    .padding(.top, 4)
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("최근 자격진단 이력이 존재하지 않습니다.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        appState.selectedTab = 2 // 자격진단 탭
                    } label: {
                        Text("3분만에 내 자격 확인하기 ➔")
                            .font(.caption.bold())
                            .foregroundStyle(Color.imMint)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .glassmorphicCard()
    }
}

#Preview {
    MyPageView()
        .environmentObject(AppState())
}
