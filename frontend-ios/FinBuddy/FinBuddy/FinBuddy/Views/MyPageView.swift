import SwiftUI

struct MyPageView: View {
    @EnvironmentObject private var appState: AppState
    
    // 로컬 UserDefaults 저장 프로퍼티
    @AppStorage("fb_nickname") private var nickname: String = ""
    @AppStorage("fb_marketing_consent") private var marketingConsent: Bool = false
    @AppStorage("fb_data_consent") private var dataConsent: Bool = true
    @AppStorage("fb_visa_type") private var visaType: String = "E-9 (비전문취업)"
    @AppStorage("fb_pref_language") private var prefLanguage: String = "ko"
    @AppStorage("fb_monthly_savings") private var monthlySavings: Double = 1000000.0
    @AppStorage("fb_entry_date_interval") private var entryDateInterval: Double = Date().timeIntervalSince1970
    @AppStorage("fb_nationality") private var nationality: String = "베트남"

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                    
                    // 1. 자격진단 결과 요약 대시보드 카드 (프로필 최상단에 노출)
                    diagnosisSummaryCard
                        .padding(.horizontal)
                    
                    // 2. 프로필 설정 카드 (Toss 스타일 프리미엄 글래스 카드)
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.imMint)
                            Text("나의 프로필 설정")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        // A. 닉네임 입력
                        VStack(alignment: .leading, spacing: 6) {
                            Text("닉네임")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            TextField("닉네임 입력 (예: 홍길동)", text: $nickname)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        }
                        
                        // A-2. 국적 선택
                        VStack(alignment: .leading, spacing: 6) {
                            Text("국적 (Nationality)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            Picker("국적", selection: $nationality) {
                                Text("베트남 🇻🇳").tag("베트남")
                                Text("중국 🇨🇳").tag("중국")
                                Text("필리핀 🇵🇭").tag("필리핀")
                                Text("캄보디아 🇰🇭").tag("캄보디아")
                                Text("인도네시아 🇮🇩").tag("인도네시아")
                                Text("태국 🇹🇭").tag("태국")
                                Text("기타 국적 🌍").tag("기타")
                            }
                            .pickerStyle(.menu)
                            .tint(.imMint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // B. 비자 유형 선택
                        VStack(alignment: .leading, spacing: 6) {
                            Text("비자 유형 (Visa Type)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            Picker("비자 유형", selection: $visaType) {
                                Text("E-9 (비전문취업)").tag("E-9 (비전문취업)")
                                Text("E-7 (특정활동)").tag("E-7 (특정활동)")
                                Text("F-2 (거주)").tag("F-2 (거주)")
                                Text("F-5 (영주)").tag("F-5 (영주)")
                                Text("기타 비자").tag("기타 비자")
                            }
                            .pickerStyle(.menu)
                            .tint(.imMint)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        
                        // C. 최근 입국일 설정
                        VStack(alignment: .leading, spacing: 6) {
                            Text("최근 입국일 (Date of Entry)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { Date(timeIntervalSince1970: entryDateInterval) },
                                        set: { entryDateInterval = $0.timeIntervalSince1970 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                
                                Spacer()
                                
                                let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: Date(timeIntervalSince1970: entryDateInterval)), to: Calendar.current.startOfDay(for: Date())).day ?? 0
                                Text("체류 \(days)일째 (\(days >= 183 ? "거주자" : "비거주자"))")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(days >= 183 ? Color.imMint : .orange)
                            }
                        }
                        
                        // D. 선호 언어 설정
                        VStack(alignment: .leading, spacing: 6) {
                            Text("선호 언어 (Preferred Language)")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            
                            Picker("선호 언어", selection: $prefLanguage) {
                                Text("한국어 🇰🇷").tag("ko")
                                Text("English 🇺🇸").tag("en")
                                Text("Tiếng Việt 🇻🇳").tag("vi")
                                Text("中文 🇨🇳").tag("zh")
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // E. 월 목표 저축액
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("월 목표 저축액")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("₩\(Int(monthlySavings).formatted())")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.imMint)
                            }
                            
                            Slider(value: $monthlySavings, in: 100000...5000000, step: 100000)
                                .tint(Color.imMint)
                        }
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
                        
                        Divider()
                            .padding(.vertical, 4)
                        
                        Text("핀버디의 행동데이터 리포트는 신용평가(CSS)를 대체하지 않으며, 국내 신용이력이 부족한 고객에 대한 보조 참고자료입니다. 최종 대출 심사와 판단은 반드시 금융기관 여신심사역이 수행합니다.")
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
