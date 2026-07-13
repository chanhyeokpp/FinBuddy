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
                        // 웰컴 인사말
                        VStack(alignment: .leading, spacing: 4) {
                            Text("안녕하세요 👋")
                                .font(.title2.bold())
                                .foregroundStyle(.primary)
                            Text("오늘의 금융 정책 소식을 확인해보세요")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // 2. 개인화 세금 혜택 전광판 배너 (Tax Dashboard)
                        taxSavingGaugeCard
                            .padding(.horizontal)
                        
                        // 3. 절세 투자 포트폴리오 안내 시트 (진단 완료시에만 활성화)
                        if appState.isDiagnosed {
                            portfolioCardBanner
                                .padding(.horizontal)
                        }
                        
                        // 4. 정책 카드 피드 리스트
                        VStack(spacing: 16) {
                            ForEach(items) { item in
                                PolicyCard(item: item, selectedJargon: $selectedJargon, isShowingJargonTooltip: $isShowingJargonTooltip)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("핀버디")
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

    // 자격진단 결과 연동형 개인화 세금 혜택 대시보드 카드
    private var taxSavingGaugeCard: some View {
        Button {
            appState.selectedTab = 2 // 자격진단 탭으로 연결
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Image(systemName: appState.isDiagnosed ? "sparkles" : "shield.checkerboard")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.imMintLimeGradient)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.isDiagnosed ? "나의 세금 혜택 현황" : "나에게 맞는 금융 상품은?")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(appState.isDiagnosed ? appState.diagnosisSummary : "3분 만에 내 절세 자격 확인하기 ➔")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                if appState.isDiagnosed {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("올해 아낄 수 있는 세금")
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("최대 ₩1,180,000")
                                .font(.caption.bold())
                                .foregroundStyle(Color.imMint)
                        }
                        
                        // 게이지 게이지 차트 렌더링
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.black.opacity(0.04))
                                    .frame(height: 8)
                                
                                Capsule()
                                    .fill(Color.imMintLimeGradient)
                                    .frame(width: geo.size.width * 0.8, height: 8)
                            }
                        }
                        .frame(height: 8)
                        
                        Text("🎉 연 118만원 절세 혜택 가능! 하단 포트폴리오를 확인해보세요.")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        appState.isDiagnosed ? Color.imMint.opacity(0.3) : Color.white.opacity(0.6),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 3)
        }
    }

    // 포트폴리오 리포트 시트 실행 배너 (3D 드래그 입체 카드 버전)
    private var portfolioCardBanner: some View {
        GlassCard3D {
            isShowingPortfolio = true
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
