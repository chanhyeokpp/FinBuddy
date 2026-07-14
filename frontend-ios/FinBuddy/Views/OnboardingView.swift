import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var currentPage = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var isSpinning = false
    
    var body: some View {
        ZStack {
            // 일렁이는 민트-라임 오로라 배경 탑재
            AuroraBackgroundView()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 3단계 카드형 페이지 슬라이더
                TabView(selection: $currentPage) {
                    // 페이지 1: 단디 환영
                    OnboardingCard(
                        imageName: "onboarding_welcome",
                        title: "환영해요! 저는 단디입니다 🐥",
                        description: "어려운 한국 금융 제도와 세법 용어 때문에\n매번 예적금만 들고 계시진 않았나요?\n핀버디가 자산 성장의 길잡이가 되어 드릴게요."
                    )
                    .tag(0)
                    
                    // 페이지 2: 똑디 진단
                    OnboardingCard(
                        imageName: "onboarding_diagnose",
                        title: "똑디와 함께하는 3분 자격 진단 🔍",
                        description: "귀하의 거주 비자(Visa) 유형과 근로 소득 수준에 딱 맞춘\n비과세 ISA 및 연금저축 공제 자격을 똑똑하게 판단합니다."
                    )
                    .tag(1)
                    
                    // 페이지 3: 우디 QR 공유
                    OnboardingCard(
                        imageName: "onboarding_qr",
                        title: "우디와 함께 QR 코드로 바로 연계 📲",
                        description: "진단서와 앱 내 활동 로그가 암호화된 QR 코드를 생성해\niM뱅크 창구 행원에게 보여주고 1:1 맞춤 대출/절세 상품 상담을 연계하세요."
                    )
                    .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(maxHeight: 520)
                
                Spacer()
                
                // 하단 인터랙션 컨트롤 (글래스모피즘 넥스트/시작 버튼)
                HStack {
                    if currentPage < 2 {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } label: {
                            Text("다음 단계")
                                .font(.headline)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .glassmorphicCard()
                        }
                    } else {
                        Button {
                            // UserDefaults 저장 및 앱 주 메인화면으로 이동 진입
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                                UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
                                appState.hasSeenOnboarding = true
                            }
                        } label: {
                            Text("핀버디 시작하기")
                                .font(.headline.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.imMintLimeGradient)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: Color.imMint.opacity(0.3), radius: 8, y: 4)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// 온보딩 단일 카드 템플릿 (각 카드별로 개별적인 물리 애니메이션 독립 구동)
private struct OnboardingCard: View {
    let imageName: String
    let title: String
    let description: String
    
    @State private var bounceOffset: CGFloat = -6
    @State private var scaleEffect: CGFloat = 0.98
    @State private var rotationAngle: Double = -1.5
    
    var body: some View {
        VStack(spacing: 28) {
            // 캐릭터 3D 렌더링 프레임
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
                .offset(y: bounceOffset)
                .scaleEffect(scaleEffect)
                .rotationEffect(.degrees(rotationAngle))
                .onAppear {
                    // 1. 위아래 둥실둥실 바운스 루프 (2.4초 주기)
                    withAnimation(
                        .easeInOut(duration: 2.4)
                        .repeatForever(autoreverses: true)
                    ) {
                        bounceOffset = 6
                    }
                    
                    // 2. 부드럽게 커졌다 작아지는 호흡 루프 (2.0초 주기)
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        scaleEffect = 1.03
                    }
                    
                    // 3. 은은한 좌우 끄덕임 루프 (3.2초 주기)
                    withAnimation(
                        .easeInOut(duration: 3.2)
                        .repeatForever(autoreverses: true)
                    ) {
                        rotationAngle = 1.5
                    }
                }
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 10)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
