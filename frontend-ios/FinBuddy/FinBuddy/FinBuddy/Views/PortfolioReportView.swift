import SwiftUI

/// 고객의 자격진단 상태와 투자 성향을 기반으로 비과세 포트폴리오를 제공하는 뷰
struct PortfolioReportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState

    @State private var annualDeposit: Double = 6000000 // 연금저축 시뮬레이터 기본 600만원 설정

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 요약 타이틀 헤더
                    VStack(spacing: 6) {
                        Text("나의 맞춤형 절세 포트폴리오")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                        Text("자격진단 결과 및 세제 한도를 결합한 최적 자산 배분")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 14)
                    
                    // 도넛형 자산배분 차트 (Donut Chart)
                    ZStack {
                        // 세그먼트 1: 안전자산 예적금 50%
                        Circle()
                            .trim(from: 0.0, to: 0.5)
                            .stroke(Color.imMint, lineWidth: 32)
                        
                        // 세그먼트 2: 수익자산 국내주식형 ETF 30%
                        Circle()
                            .trim(from: 0.5, to: 0.8)
                            .stroke(Color.imLime, lineWidth: 32)
                        
                        // 세그먼트 3: 안정펀드 글로벌채권 20%
                        Circle()
                            .trim(from: 0.8, to: 1.0)
                            .stroke(Color.blue.opacity(0.65), lineWidth: 32)
                        
                        // 차트 중심 텍스트 요약
                        VStack(spacing: 4) {
                            Text("비과세 한도")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("₩4,000,000")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                            Text("세금 절감액: ₩61.6만")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.imMint)
                        }
                    }
                    .frame(width: 190, height: 190)
                    .rotationEffect(.degrees(-90)) // 12시 방향 출발
                    .padding(.vertical, 10)
                    
                    // 자산별 비중 범례 (Legend Cards)
                    VStack(spacing: 12) {
                        HStack {
                            Circle().fill(Color.imMint).frame(width: 10, height: 10)
                            Text("안전 자산 (고금리 예적금)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("50%")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        HStack {
                            Circle().fill(Color.imLime).frame(width: 10, height: 10)
                            Text("수익형 자산 (국내 주식형 ETF)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("30%")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        HStack {
                            Circle().fill(Color.blue.opacity(0.65)).frame(width: 10, height: 10)
                            Text("안정형 펀드 (글로벌 채권형)")
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Text("20%")
                                .font(.subheadline.bold())
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding(18)
                    .glassmorphicCard()
                    .padding(.horizontal)
                    
                    // 2. 납입액 시뮬레이터 (액체 비커 탑재)
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "drop.triangle.fill")
                                .foregroundStyle(Color.imMint)
                            Text("연금저축 납입 시뮬레이터")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        HStack(spacing: 20) {
                            // 비커 컴포넌트 렌더링
                            LiquidBeakerView(fillRatio: annualDeposit / 12000000.0)
                                .frame(width: 110, height: 180)
                            
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("연간 납입 목표액")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("₩\(Int(annualDeposit).formatted())")
                                        .font(.title3.bold())
                                        .foregroundStyle(.primary)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("💰 예상 환급 세액 (16.5%)")
                                        .font(.caption.bold())
                                        .foregroundStyle(Color.imMint)
                                    
                                    // 연말정산 최대 환급 한도인 600만원 기준 환급 연산 (최대 99만원)
                                    let maxEligibleAmount = min(annualDeposit, 6000000.0)
                                    let refund = Int(maxEligibleAmount * 0.165)
                                    Text("₩\(refund.formatted())")
                                        .font(.title2.bold())
                                        .foregroundStyle(.primary)
                                    
                                    if annualDeposit > 6000000.0 {
                                        Text("* 연금저축 세액공제 최대한도(600만원) 초과")
                                            .font(.system(size: 9))
                                            .foregroundStyle(.orange)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                            Spacer()
                        }
                        
                        // 슬라이더 조절바
                        VStack(spacing: 4) {
                            Slider(value: $annualDeposit, in: 0...12000000, step: 500000)
                                .tint(Color.imMint)
                            
                            HStack {
                                Text("0원")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("600만(최대)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("1,200만원")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(18)
                    .glassmorphicCard()
                    .padding(.horizontal)
                    
                    // 절세 가이드 상세 내용 카드
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(Color.imMint)
                            Text("절세 전략 및 투자 가이드")
                                .font(.headline.bold())
                                .foregroundStyle(.primary)
                        }
                        
                        Divider()
                        
                        Text("1. 서민형 ISA 비과세 혜택 연계")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("귀하는 '서민형 ISA' 대상자로서 일반형(200만원)보다 배로 높은 400만원 한도로 이자/배당 소득 비과세를 받습니다. 예금 이율이 높거나 ETF 분배금이 많은 고수익형 배당 상품을 이 계좌에 우선적으로 담으시는 것이 절세율을 극대화합니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            
                        Text("2. 연금저축 납입을 통한 세액공제 환급")
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text("연금저축펀드 계좌에 연간 600만원을 채워 납입할 경우, 세액공제율 최대 16.5%를 적용받아 연말정산 시 약 99만원을 현금으로 고스란히 환급받을 수 있습니다. 납입 한도 금액은 손실 우려가 덜한 채권형 펀드에 20% 수준으로 안전하게 거치할 것을 제안합니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(4)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(18)
                    .glassmorphicCard()
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(AuroraBackgroundView()) // 움직이는 오로라 메쉬 적용
            .navigationTitle("포트폴리오 리포트")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.imMint)
                }
            }
        }
    }
}

#Preview {
    PortfolioReportView()
        .environmentObject(AppState())
}
