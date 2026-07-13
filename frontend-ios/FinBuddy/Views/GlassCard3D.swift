import SwiftUI

/// 드래그 제스처에 따라 3D로 기울어지며 엠비언트 그림자와 쉬머 광택이 일렁이는 프리미엄 입체 카드 컴포넌트
struct GlassCard3D: View {
    let onTap: () -> Void

    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var shimmerOffset: CGFloat = -1.2

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 카드 상단 로고
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.white)
                    Text("iM FinBuddy")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                
                Image(systemName: "creditcard.and.123")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))
            }
            
            Spacer()
            
            // 카드 하단 텍스트 및 안내
            VStack(alignment: .leading, spacing: 6) {
                Text("GLOBAL PREMIUM PORTFOLIO")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.7))
                    .tracking(1)
                
                HStack(alignment: .bottom) {
                    Text("절세 포트폴리오 카드")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    Text("자격 진단 완료 ➔")
                        .font(.caption2.bold())
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(24)
        .frame(height: 200)
        .background(
            ZStack {
                // 1. 민트 - 라임 - 블루 엠비언트 입체 카드 그라데이션
                LinearGradient(
                    colors: [
                        Color.imMint.opacity(0.85),
                        Color.imLime.opacity(0.70),
                        Color(red: 0.1, green: 0.45, blue: 0.85).opacity(0.6)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // 2. 글래스 텍스쳐용 미세 반사 오버레이
                Color.white.opacity(0.06)
                
                // 3. 루핑 쉬머 광선 (Shimmer Reflection Sweep)
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .offset(x: shimmerOffset * geo.size.width)
                    .blendMode(.plusLighter)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.1), .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        // 4. 3D 입체 기울기 적용 (가로/세로 각각 회전축 지정)
        .rotation3DEffect(
            .degrees(Double(dragOffset.width / 8)),
            axis: (x: 0, y: 1, z: 0)
        )
        .rotation3DEffect(
            .degrees(Double(-dragOffset.height / 8)),
            axis: (x: 1, y: 0, z: 0)
        )
        // 드래그 시 커지며 그림자도 손가락 움직임 방향으로 흐르게 설정
        .shadow(
            color: Color.imMint.opacity(isDragging ? 0.35 : 0.18),
            radius: isDragging ? 22 : 12,
            x: dragOffset.width / 2.5,
            y: 8 + dragOffset.height / 2.5
        )
        .scaleEffect(isDragging ? 1.03 : 1.0)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { gesture in
                    withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.6)) {
                        dragOffset = gesture.translation
                        isDragging = true
                    }
                }
                .onEnded { gesture in
                    // 아주 미세한 움직임이거나 단순 탭이면 클릭 액션 동작
                    if abs(gesture.translation.width) < 6 && abs(gesture.translation.height) < 6 {
                        onTap()
                    }
                    
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.62)) {
                        dragOffset = .zero
                        isDragging = false
                    }
                }
        )
        .onAppear {
            // 카드의 사선 광택 쉬머 애니메이션 무한 반복 작동
            withAnimation(
                .easeInOut(duration: 4.0)
                .repeatForever(autoreverses: false)
            ) {
                shimmerOffset = 2.2
            }
        }
    }
}

#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        GlassCard3D(onTap: {})
    }
}
