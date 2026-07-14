import SwiftUI

struct OCRScannerView: View {
    @ObservedObject var vm: EligibilityViewModel
    @Binding var currentStep: Int
    @Environment(\.dismiss) private var dismiss
    
    @State private var scanLineY: CGFloat = -110
    @State private var isScanning = false
    @State private var showSuccessBadge = false
    @State private var detectedVisa = ""
    @State private var detectedAge = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 1. 카메라 스캐너 어두운 배경 오버레이
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                // 일렁이는 백그라운드 효과 부여
                RadialGradient(
                    gradient: Gradient(colors: [Color.imMint.opacity(0.12), .clear]),
                    center: .center,
                    startRadius: 50,
                    endRadius: 300
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // 상단 가이드 텍스트
                    VStack(spacing: 8) {
                        Text("외국인등록증 / 거소신고증 스캔")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        
                        Text("신분증 앞면이 아래 녹색 박스에 들어가도록 맞춰주세요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 30)
                    
                    Spacer()
                    
                    // 2. 신분증 가이드 영역 (스캔 레이저 빔 애니메이션 프레임)
                    ZStack {
                        // 신분증 형태의 모형 카드 플레이트
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.03))
                            .frame(width: 320, height: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isScanning ? Color.imMint : Color.white.opacity(0.4), lineWidth: 2)
                            )
                        
                        // 구석 네 모서리 브라켓 엣지 데코
                        cardBracketOverlay
                        
                        // 녹색 레이저 빔 (루핑 무한 상하 이동 애니메이션)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.clear, Color.imMint, .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 300, height: 6)
                            .shadow(color: Color.imMint.opacity(0.8), radius: 4, y: 0)
                            .offset(y: scanLineY)
                            .opacity(showSuccessBadge ? 0 : 1)
                        
                        // 판독 성공 체크마크 뱃지
                        if showSuccessBadge {
                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 54))
                                    .foregroundStyle(Color.imMint)
                                    .transition(.scale.combined(with: .opacity))
                                
                                Text("추출 완료: \(detectedVisa) / 만 \(detectedAge)세")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Color.imMint.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // 스캐닝 분석 로딩 스피너
                        if isScanning && !showSuccessBadge {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.3)
                                
                                Text("똑디가 신분증 정보를 해독 중...")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.imMint)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .frame(height: 220)
                    
                    Spacer()
                    
                    // 3. 테스트 목적의 데모 시뮬레이션 제어부 (심사용)
                    VStack(spacing: 14) {
                        Text("💡 심사위원용 데모 스캔 샘플 버튼")
                            .font(.caption.bold())
                            .foregroundStyle(Color.imMint)
                        
                        HStack(spacing: 16) {
                            Button {
                                simulateScan(visa: "E-9 (비전문취업)", age: 27, income: true, incomeType: .employed)
                            } label: {
                                VStack(spacing: 4) {
                                    Text("샘플 A (E-9)")
                                        .font(.subheadline.bold())
                                    Text("제조직 근로자/만27세")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .disabled(isScanning)
                            
                            Button {
                                simulateScan(visa: "D-2 (유학 비자)", age: 22, income: false, incomeType: .none)
                            } label: {
                                VStack(spacing: 4) {
                                    Text("샘플 B (D-2)")
                                        .font(.subheadline.bold())
                                    Text("대학 유학생/만22세")
                                        .font(.system(size: 10))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                            }
                            .disabled(isScanning)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("신분증 인식")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
            .onAppear {
                startLaserAnimation()
            }
        }
    }
    
    // 레이저 빔 무한 상하 팅김 루프
    private func startLaserAnimation() {
        withAnimation(
            .easeInOut(duration: 1.8)
            .repeatForever(autoreverses: true)
        ) {
            scanLineY = 110
        }
    }
    
    // 가상 OCR 스캔 처리 루프 시뮬레이션
    private func simulateScan(visa: String, age: Int, income: Bool, incomeType: IncomeType) {
        isScanning = true
        detectedVisa = visa
        detectedAge = age
        
        // 레이저 스캔 속도 초고속 변경
        withAnimation(.linear(duration: 0.25).repeatForever(autoreverses: true)) {
            scanLineY = scanLineY == 110 ? -110 : 110
        }
        
        // 2초 뒤 스캔 결과 데이터 주입 및 성공 확인창 기동
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showSuccessBadge = true
            
            // ViewModel 세팅 (바인딩 적용)
            vm.isResident = true
            vm.age = age
            vm.hadIncomeLastYear = income
            vm.incomeType = incomeType
            vm.hasComprehensiveTax = false
            
            // 1.2초 대기 후 스크린 자동 닫기 및 퀴즈 마지막 리뷰단계로 다이렉트 이송
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.spring()) {
                    currentStep = 5 // 최종 과세 단계로 바로 포워딩
                    dismiss()
                }
            }
        }
    }
    
    // 카드 코너 브라켓 형상 레이아웃
    private var cardBracketOverlay: some View {
        GeometryReader { _ in
            ZStack {
                // 좌상단 코너
                Path { p in
                    p.move(to: CGPoint(x: 10, y: 30))
                    p.addLine(to: CGPoint(x: 10, y: 10))
                    p.addLine(to: CGPoint(x: 30, y: 10))
                }
                .stroke(Color.imMint, lineWidth: 4)
                
                // 우상단 코너
                Path { p in
                    p.move(to: CGPoint(x: 310, y: 30))
                    p.addLine(to: CGPoint(x: 310, y: 10))
                    p.addLine(to: CGPoint(x: 290, y: 10))
                }
                .stroke(Color.imMint, lineWidth: 4)
                
                // 좌하단 코너
                Path { p in
                    p.move(to: CGPoint(x: 10, y: 190))
                    p.addLine(to: CGPoint(x: 10, y: 210))
                    p.addLine(to: CGPoint(x: 30, y: 210))
                }
                .stroke(Color.imMint, lineWidth: 4)
                
                // 우하단 코너
                Path { p in
                    p.move(to: CGPoint(x: 310, y: 190))
                    p.addLine(to: CGPoint(x: 310, y: 210))
                    p.addLine(to: CGPoint(x: 290, y: 210))
                }
                .stroke(Color.imMint, lineWidth: 4)
            }
        }
        .frame(width: 320, height: 220)
    }
}
