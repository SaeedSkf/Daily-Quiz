import SwiftUI

struct ConfettiView: View {
    @State private var isAnimating = false
    let confettiColors: [Color] = [.red, .blue, .green, .yellow, .pink, .purple, .orange]
    let confettiCount = 100
    
    var body: some View {
        ZStack {
            ForEach(0..<confettiCount, id: \.self) { index in
                ConfettiPiece(
                    color: confettiColors[index % confettiColors.count],
                    position: randomPosition(),
                    size: randomSize(),
                    rotation: randomAngle(),
                    animationDelay: Double.random(in: 0...1),
                    animationDuration: Double.random(in: 1...3)
                )
                .opacity(isAnimating ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation {
                isAnimating = true
            }
        }
    }
    
    private func randomPosition() -> CGPoint {
        return CGPoint(
            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
            y: CGFloat.random(in: -100...0)
        )
    }
    
    private func randomSize() -> CGFloat {
        return CGFloat.random(in: 5...15)
    }
    
    private func randomAngle() -> Double {
        return Double.random(in: 0...360)
    }
}

struct ConfettiPiece: View {
    let color: Color
    let position: CGPoint
    let size: CGFloat
    let rotation: Double
    let animationDelay: Double
    let animationDuration: Double
    
    @State private var offsetY: CGFloat = 0
    @State private var rotation3D: Double = 0
    
    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: rotation))
            .rotation3DEffect(
                Angle(degrees: rotation3D),
                axis: (x: CGFloat.random(in: 0...1), y: CGFloat.random(in: 0...1), z: CGFloat.random(in: 0...1))
            )
            .position(x: position.x, y: position.y + offsetY)
            .onAppear {
                withAnimation(
                    Animation
                        .easeOut(duration: animationDuration)
                        .delay(animationDelay)
                        .repeatForever(autoreverses: false)
                ) {
                    offsetY = UIScreen.main.bounds.height + 100
                    rotation3D = Double.random(in: 360...720)
                }
            }
    }
} 