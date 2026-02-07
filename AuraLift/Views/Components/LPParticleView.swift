import SwiftUI

/// Floating "+LP" text particles that animate upward and fade out.
struct LPParticleView: View {
    let particles: [LPParticle]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                LPParticleItem(particle: particle)
            }
        }
    }
}

// MARK: - Single Particle

private struct LPParticleItem: View {
    let particle: LPParticle

    @State private var offsetY: CGFloat = 0
    @State private var opacity: Double = 1.0

    var body: some View {
        Text("+\(particle.value) LP")
            .font(.system(size: 16, weight: .heavy, design: .monospaced))
            .cyberpunkText(color: .neonGold)
            .shadow(color: .neonGold.opacity(0.6), radius: 6)
            .position(x: particle.position.x, y: particle.position.y + offsetY)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offsetY = -60
                    opacity = 0
                }
            }
    }
}
