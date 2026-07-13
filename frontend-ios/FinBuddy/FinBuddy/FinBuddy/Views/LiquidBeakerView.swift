import SwiftUI

struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var size: CGFloat
    var opacity: Double
}

/// SwiftUI TimelineView와 Canvas를 결합하여 만든 60fps 실시간 액체 파동 및 버블 상승 비커 시뮬레이터
struct LiquidBeakerView: View {
    /// 비커 액체 높이 비율 (0.0 ~ 1.0)
    let fillRatio: Double

    @State private var bubbles: [Bubble] = []
    @State private var lastUpdateTime: Date = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let width = size.width
                let height = size.height
                
                // 액체 수면 Y 좌표 계산 (fillRatio에 따라 변화, 상단 10% 여유)
                let targetWaveY = height - (height * CGFloat(fillRatio) * 0.85)
                
                // 1. 버블 파티클 데이터 업데이트 및 드로잉
                updateBubbles(in: size, waveY: targetWaveY)
                
                for bubble in bubbles {
                    let bubbleRect = CGRect(x: bubble.x, y: bubble.y, width: bubble.size, height: bubble.size)
                    context.fill(
                        Path(ellipseIn: bubbleRect),
                        with: .color(Color.white.opacity(bubble.opacity))
                    )
                }

                // 2. 이중 파도 그리기 (더 풍성한 부피감을 위한 합성 파동)
                var frontPath = Path()
                var backPath = Path()
                
                frontPath.move(to: CGPoint(x: 0, y: height))
                backPath.move(to: CGPoint(x: 0, y: height))
                
                // X축을 따라 파도 모양 생성
                for x in stride(from: 0, through: width, by: 4) {
                    let relativeX = Double(x) / Double(width)
                    
                    // 전면부 파동 계산 (빠르게 흐르는 큰 물결)
                    let frontAngle = relativeX * Double.pi * 2.0
                    let frontSine = sin(frontAngle + time * 4.0) * 7.0
                    let frontCosine = cos(frontAngle * 1.5 - time * 3.0) * 4.0
                    let frontY = targetWaveY + CGFloat(frontSine + frontCosine)
                    frontPath.addLine(to: CGPoint(x: x, y: frontY))
                    
                    // 후면부 파동 계산 (느리게 일렁이는 보조 물결)
                    let backAngle = relativeX * Double.pi * 3.0
                    let backSine = sin(backAngle - time * 2.2) * 5.0
                    let backCosine = cos(backAngle * 0.8 + time * 1.5) * 3.0
                    let backY = targetWaveY - 4.0 + CGFloat(backSine + backCosine)
                    backPath.addLine(to: CGPoint(x: x, y: backY))
                }
                
                // 패스 완성 및 하단 모서리 연결
                frontPath.addLine(to: CGPoint(x: width, y: height))
                frontPath.addLine(to: CGPoint(x: 0, y: height))
                frontPath.closeSubpath()
                
                backPath.addLine(to: CGPoint(x: width, y: height))
                backPath.addLine(to: CGPoint(x: 0, y: height))
                backPath.closeSubpath()
                
                // 3. 물결 드로잉 (전면/후면 오버랩)
                // 후면 물결: 진한 민트색 반투명
                context.fill(
                    backPath,
                    with: .linearGradient(
                        Gradient(colors: [Color.imMint.opacity(0.4), Color.blue.opacity(0.3)]),
                        startPoint: CGPoint(x: 0, y: targetWaveY),
                        endPoint: CGPoint(x: 0, y: height)
                    )
                )
                
                // 전면 물결: 상큼한 민트-라임 에메랄드빛 그라데이션
                context.fill(
                    frontPath,
                    with: .linearGradient(
                        Gradient(colors: [Color.imMint.opacity(0.85), Color.imLime.opacity(0.75)]),
                        startPoint: CGPoint(x: 0, y: targetWaveY),
                        endPoint: CGPoint(x: 0, y: height)
                    )
                )
                
                // 4. 비커 유리에 비치는 하이라이트 광택선 드로잉
                let glassReflect = Path(roundedRect: CGRect(x: 10, y: 10, width: width - 20, height: height - 20), cornerRadius: 20)
                context.stroke(
                    glassReflect,
                    with: .color(.white.opacity(0.15)),
                    lineWidth: 1.5
                )
            }
            .background(
                // 반투명 유리 용기 뒷배경
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.black.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .onAppear {
            initializeBubbles()
        }
    }

    /// 버블 파티클 초기화
    private func initializeBubbles() {
        bubbles = (0..<15).map { _ in
            createRandomBubble(atBottom: false)
        }
    }

    /// 프레임 업데이트 시 호출되어 버블을 부상시키고 재생성하는 물리 루프
    private func updateBubbles(in size: CGSize, waveY: CGFloat) {
        let currentTime = Date()
        let deltaTime = CGFloat(currentTime.timeIntervalSince(lastUpdateTime))
        
        // 너무 큰 프레임 갭 보정
        let clampedDelta = min(deltaTime, 0.03) 
        
        for i in 0..<bubbles.count {
            // 시간 변화율에 맞춰 서서히 위로 이동
            bubbles[i].y -= bubbles[i].speed * clampedDelta * 60.0
            
            // 수면에 닿으면 거품이 터지듯 소멸하고 바닥에서 재생성
            if bubbles[i].y <= waveY + 5 {
                bubbles[i] = createRandomBubble(atBottom: true)
            }
        }
        
        // 버블이 부족하면 유동적으로 보충
        if bubbles.count < 22 && fillRatio > 0.1 {
            bubbles.append(createRandomBubble(atBottom: true))
        }
        
        // 강제로 시간 보관 변수 업데이트 (Task 환경 스레드 세이프 확보)
        DispatchQueue.main.async {
            self.lastUpdateTime = currentTime
        }
    }

    /// 새로운 랜덤 방울 생성
    private func createRandomBubble(atBottom: Bool) -> Bubble {
        let sizeRange = CGFloat.random(in: 4...9)
        let randomY = atBottom ? CGFloat.random(in: 180...200) : CGFloat.random(in: 30...180)
        return Bubble(
            x: CGFloat.random(in: 15...125),
            y: randomY,
            speed: CGFloat.random(in: 1.2...3.5),
            size: sizeRange,
            opacity: Double.random(in: 0.15...0.6)
        )
    }
}

#Preview {
    LiquidBeakerView(fillRatio: 0.6)
        .frame(width: 140, height: 200)
}
