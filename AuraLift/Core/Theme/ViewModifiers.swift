import SwiftUI

// MARK: - Aurea Glow Card Modifier

struct AureaGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(Color.aureaSurface)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.3), radius: radius, x: 0, y: 0)
    }
}

// MARK: - Aurea Text Style

struct AureaTextModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 0)
    }
}

// MARK: - Aurea Card Background

struct AureaCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AureaTheme.Spacing.lg)
            .background(Color.aureaSurfaceElevated)
            .cornerRadius(AureaTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AureaTheme.Radius.medium)
                    .stroke(Color.aureaBorder, lineWidth: 0.5)
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
    func aureaGlow(
        color: Color = .aureaPrimary,
        radius: CGFloat = AureaTheme.Shadows.glowRadius,
        cornerRadius: CGFloat = AureaTheme.Radius.medium
    ) -> some View {
        modifier(AureaGlowModifier(color: color, radius: radius, cornerRadius: cornerRadius))
    }

    func aureaText(color: Color = .aureaPrimary) -> some View {
        modifier(AureaTextModifier(color: color))
    }

    func aureaCard() -> some View {
        modifier(AureaCardModifier())
    }

    func pulse() -> some View {
        modifier(PulseModifier())
    }

    // MARK: - Legacy Aliases

    func neonGlow(
        color: Color = .aureaPrimary,
        radius: CGFloat = AureaTheme.Shadows.glowRadius,
        cornerRadius: CGFloat = AureaTheme.Radius.medium
    ) -> some View {
        aureaGlow(color: color, radius: radius, cornerRadius: cornerRadius)
    }

    func cyberpunkText(color: Color = .aureaPrimary) -> some View {
        aureaText(color: color)
    }

    func darkCard() -> some View {
        aureaCard()
    }
}
