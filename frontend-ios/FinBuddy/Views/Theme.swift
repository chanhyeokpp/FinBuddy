import SwiftUI

extension Color {
    // iM뱅크 브랜드 정체성을 담은 민트와 라임 색상 정의
    static let imMint = Color(red: 0.0, green: 0.85, blue: 0.70)   // #00D8B2
    static let imLime = Color(red: 0.65, green: 0.88, blue: 0.10)   // #A6E01A
    
    // 그라데이션 편리용
    static let imMintLimeGradient = LinearGradient(
        colors: [.imMint, .imLime],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// iM뱅크 브랜드 컬러 테두리와 투명 유리 재질을 가진 버튼 스타일
struct GlassmorphicButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.primary)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        Color.imMintLimeGradient.opacity(0.6),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 토스 스타일의 깔끔한 글래스모피즘 카드 컨테이너용 모디파이어
struct GlassmorphicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        Color.white.opacity(0.6),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassmorphicCard() -> some View {
        self.modifier(GlassmorphicCardModifier())
    }
    
    /// iM뱅크 민트 컬러 광택 그림자 효과 추가
    func accentGlow() -> some View {
        self.shadow(color: Color.imMint.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}
