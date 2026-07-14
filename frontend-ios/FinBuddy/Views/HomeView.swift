import SwiftUI

struct PolicyItem: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let tag: String
    let iconName: String
    let chatQuestion: String
    let keywords: [String]
}

struct HomeView: View {
    @EnvironmentObject private var appState: AppState
    
    @State private var isShowingPortfolio = false
    @State private var isShowingJargonTooltip = false
    @State private var selectedJargon = ""
    
    // 마스코트 애니메이션용 오프셋
    @State private var heroBounceOffset: CGFloat = -6
    
    // 저축 의도 클릭 시 말풍선 안내 오버레이 문구
    @State private var transitionText: String? = nil

    // 각 피드 카드 정보에 다국어 해설 번역 연계 키워드 추가
    private let items: [PolicyItem] = [
        PolicyItem(
            title: "ISA 비과세 한도 안내",
            summary: "총급여 5천만원 이하면 400만원까지 비과세 혜택 제공",
            tag: "ISA",
            iconName: "percent",
            chatQuestion: "ISA 비과세 한도와 일반형/서민형 혜택 차이를 설명해줘.",
            keywords: ["비과세", "서민형"]
        ),
        PolicyItem(
            title: "연금저축계좌 세액공제",
            summary: "연간 600만원 한도, 최대 900만원까지 세액공제 적용",
            tag: "연금저축",
            iconName: "banknote.fill",
            chatQuestion: "연금저축계좌 납입 한도에 따른 소득별 세액공제율을 알고 싶어.",
            keywords: ["세액공제", "연도한도"]
        ),
        PolicyItem(
            title: "외국인 종합소득세 신고",
            summary: "5.1.~5.31. 신고기간, 영어 및 다국어 상담 1588-0560",
            tag: "세무",
            iconName: "doc.text.fill",
            chatQuestion: "외국인 근로자의 종합소득세 신고 일정과 연말정산 대비 혜택을 정리해줘.",
            keywords: ["종합소득세", "세무"]
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 오로라 일렁임 메쉬 그라데이션 탑재
                AuroraBackgroundView()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // A. 의도 분기 선택 섹션 (최상단 배치)
                        intentBranchingSection
                            .padding(.top, 10)
                        
                        // B. 프리미엄 캐릭터 메인 히어로 배너
                        mascotHeroBanner
                            .padding(.horizontal)
                        
                        // C. 진단 완료 시 나타나는 계좌/절세 종합 대시보드 그리드
                        if appState.isDiagnosed {
                            // 3D 드래그 입체 카드 (포트폴리오 리포트용)
                            portfolioCardBanner
                                .padding(.horizontal)
                        }
                        
                        // D. 금융 정책 소식 타이틀 헤더
                        HStack {
                            Text("오늘의 금융 정책 소식 📰")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 6)
                        
                        // 4. 정책 카드 피드 리스트
                        VStack(spacing: 16) {
                            ForEach(items) { item in
                                PolicyCard(item: item, selectedJargon: $selectedJargon, isShowingJargonTooltip: $isShowingJargonTooltip)
                            }
                        }
                    }
                    .padding(.vertical)
                }
                
                // 저축 의도 진입 시 안내 말풍선 오버레이
                if let text = transitionText {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .transition(.opacity)
                        
                        VStack(spacing: 12) {
                            Image(systemName: "quote.bubble.fill")
                                .font(.largeTitle)
                                .foregroundStyle(Color.imMint)
                            Text(text)
                                .font(.body.bold())
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.primary)
                                .padding()
                        }
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1.5)
                        )
                        .shadow(radius: 10)
                        .padding(.horizontal, 40)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(10)
                }
            }
            .navigationTitle("핀버디")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            // 단순 데모 피드백
                        } label: {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.imMint)
                                .padding(8)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                        
                        Image("onboarding_welcome")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.imMint.opacity(0.5), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.04), radius: 4)
                    }
                }
            }
            .sheet(isPresented: $isShowingPortfolio) {
                PortfolioReportView()
            }
            // 금융 단어 번역 및 한 줄 해설 팝업 오버레이
            .overlay {
                if isShowingJargonTooltip {
                    JargonTooltipView(word: selectedJargon, isPresented: $isShowingJargonTooltip)
                        .transition(.opacity)
                }
            }
        }
    }

    // 홈화면 메인 히어로 배너 (Mascot Hero Banner)
    private var mascotHeroBanner: some View {
        Button {
            if appState.isDiagnosed {
                isShowingPortfolio = true
            } else {
                appState.selectedTab = 2 // 자격진단 탭으로 이동
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 10) {
                    if appState.isDiagnosed {
                        Text("절세 자격 분석 완료! 🎉")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.imMint)
                        
                        Text("올해 예상 환급액\n₩1,180,000 ✨")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                        
                        Text("우디와 단디가 알려준 맞춤 상품 가이드를 창구 행원에게 바로 제안해보세요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("똑디의 맞춤형 제안 💡")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.imMint)
                        
                        Text("나를 위한 숨은\n절세 혜택은 얼마? 💸")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineSpacing(4)
                        
                        Text("체류 비자(Visa)와 근로 소득을 기반으로 3분 만에 최적의 혜택을 찾아드려요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Spacer()
                
                // 마스코트 공중 부양 애니메이션 적용
                Image(appState.isDiagnosed ? "onboarding_welcome" : "onboarding_diagnose")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
                    .offset(y: heroBounceOffset)
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: 2.2)
                            .repeatForever(autoreverses: true)
                        ) {
                            heroBounceOffset = 6
                        }
                    }
            }
            .padding(20)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        appState.isDiagnosed ? Color.imMint.opacity(0.3) : Color.white.opacity(0.6),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    


    // 포트폴리오 리포트 시트 실행 배너 (3D 드래그 입체 카드 버전)
    private var portfolioCardBanner: some View {
        GlassCard3D {
            isShowingPortfolio = true
        }
    }
    
    // 의도 분기 선택 섹션
    private var intentBranchingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("무엇을 하고 싶으세요? 🤔")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // 1. 저축
                intentRowButton(
                    title: "저축하고 싶어요",
                    subtitle: "나에게 딱 맞는 비과세/절세 계좌 진단하기",
                    emoji: "🌱",
                    gradientColors: [Color.imMint, Color.imMint.opacity(0.8)]
                ) {
                    triggerSaveTransition()
                }
                
                // 2. 투자
                intentRowButton(
                    title: "투자하고 싶어요",
                    subtitle: "소액부터 불려나가는 투자 기초 Q&A",
                    emoji: "📈",
                    gradientColors: [Color.imLime, Color.imLime.opacity(0.8)]
                ) {
                    appState.chatPrefillQuestion = "투자 시작하려면 뭐부터 알아야 해?"
                    appState.shouldAutoSend = true
                    appState.selectedTab = 1
                }
                
                // 3. 금융상품
                intentRowButton(
                    title: "금융상품 알아보고 싶어요",
                    subtitle: "외국인 우대 금리 및 다양한 예적금 정보 찾기",
                    emoji: "🔍",
                    gradientColors: [Color.blue.opacity(0.7), Color.blue.opacity(0.5)]
                ) {
                    appState.chatPrefillQuestion = "어떤 금융상품들이 있어?"
                    appState.shouldAutoSend = true
                    appState.selectedTab = 1
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func intentRowButton(
        title: String,
        subtitle: String,
        emoji: String,
        gradientColors: [Color],
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // 동그라미 아이콘 컨테이너
                Text(emoji)
                    .font(.title3)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .opacity(0.15)
                    )
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(gradientColors.first ?? .clear, lineWidth: 1)
                    )
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14.5, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .glassmorphicCard()
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func triggerSaveTransition() {
        withAnimation {
            transitionText = "좋아요! 먼저 어떤 절세계좌가 맞는지 확인해볼까요? 🌱"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation {
                transitionText = nil
                appState.selectedTab = 2 // 자격진단 탭으로 이동
            }
        }
    }
}

private struct PolicyCard: View {
    let item: PolicyItem
    @Binding var selectedJargon: String
    @Binding var isShowingJargonTooltip: Bool
    
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // 상단 클릭 영역: 탭하여 챗봇으로 질문 직발송
            Button {
                appState.chatPrefillQuestion = item.chatQuestion
                appState.shouldAutoSend = true
                appState.selectedTab = 1
            } label: {
                HStack(alignment: .top, spacing: 14) {
                    // 고유 아이콘 엠블럼
                    Image(systemName: item.iconName)
                        .font(.title3)
                        .foregroundStyle(Color.imMint)
                        .frame(width: 44, height: 44)
                        .background(Color.imMint.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(item.tag)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.imMintLimeGradient)
                                .clipShape(Capsule())
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            
                        Text(item.summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // 단어 번역 버튼 칩 (Clickable Jargon Dictionary)
            if !item.keywords.isEmpty {
                Divider().padding(.vertical, 4)
                
                HStack(spacing: 8) {
                    Text("🔍 금융 용어 번역:")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    
                    ForEach(item.keywords, id: \.self) { word in
                        Button {
                            selectedJargon = word
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isShowingJargonTooltip = true
                            }
                        } label: {
                            Text(word)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.imMint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.imMint.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassmorphicCard()
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
