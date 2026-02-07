import SwiftUI

// MARK: - Neon Glow Card Modifier

struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.auraSurface)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Cyberpunk Text Style

struct CyberpunkTextModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}

// MARK: - Dark Card Background

struct DarkCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(Color.auraBorder, lineWidth: 0.5)
            )
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - View Extension

extension View {
    func neonGlow(
        color: Color = .neonBlue,
        radius: CGFloat = AuraTheme.Shadows.glowRadius,
        cornerRadius: CGFloat = AuraTheme.Radius.medium
    ) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius, cornerRadius: cornerRadius))
    }

    func cyberpunkText(color: Color = .neonBlue) -> some View {
        modifier(CyberpunkTextModifier(color: color))
    }

    func darkCard() -> some View {
        modifier(DarkCardModifier())
    }

    func pulse() -> some View {
        modifier(PulseModifier())
    }
}
