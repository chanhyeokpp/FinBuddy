import SwiftUI

/// iM뱅크의 민트-라임 컬러 엠비언트 오로라 빛이 서서히 일렁이는 움직이는 백그라운드 뷰
struct AuroraBackgroundView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            // 기본 토스풍 청량한 화이트그레이 배경
            Color(red: 0.96, green: 0.97, blue: 0.98)
                .ignoresSafeArea()
            
            // 일렁이는 반투명 그라데이션 원형들의 ZStack
            ZStack {
                // 민트색 원형 1
                Circle()
                    .fill(Color.imMint.opacity(0.12))
                    .frame(width: 380, height: 380)
                    .offset(x: animate ? -120 : 80, y: animate ? -250 : -80)
                    .scaleEffect(animate ? 1.25 : 0.85)
                
                // 라임색 원형 2
                Circle()
                    .fill(Color.imLime.opacity(0.10))
                    .frame(width: 420, height: 420)
                    .offset(x: animate ? 140 : -60, y: animate ? 120 : 260)
                    .scaleEffect(animate ? 0.9 : 1.3)
                
                // 보조 민트색 원형 3
                Circle()
                    .fill(Color.imMint.opacity(0.08))
                    .frame(width: 320, height: 320)
                    .offset(x: animate ? -40 : 160, y: animate ? 220 : -40)
                    .scaleEffect(animate ? 1.15 : 0.95)
            }
            .blur(radius: 80) // 흐릿한 뭉게구름(Mesh Gradient) 효과를 위한 블러 처리
            .ignoresSafeArea()
        }
        .onAppear {
            // 8초 주기로 부드럽게 무한 왕복하는 오로라 움직임 연출
            withAnimation(
                .easeInOut(duration: 8.0)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}

#Preview {
    AuroraBackgroundView()
}
