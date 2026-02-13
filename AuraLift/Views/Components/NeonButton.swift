import SwiftUI

/// Gold-accented button with glow effect.
struct AureaButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .aureaPrimary
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AureaTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: isCompact ? 14 : 18, weight: .bold))
                }
                Text(title)
                    .font(isCompact ? AureaTheme.Fonts.caption() : AureaTheme.Fonts.subheading())
                    .fontWeight(.bold)
            }
            .foregroundColor(.aureaVoid)
            .padding(.horizontal, isCompact ? AureaTheme.Spacing.lg : AureaTheme.Spacing.xl)
            .padding(.vertical, isCompact ? AureaTheme.Spacing.sm : AureaTheme.Spacing.md)
            .background(color)
            .cornerRadius(AureaTheme.Radius.pill)
            .shadow(color: color.opacity(0.6), radius: AureaTheme.Shadows.glowRadius, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

/// Outlined variant of AureaButton
struct AureaOutlineButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .aureaPrimary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AureaTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AureaTheme.Fonts.subheading())
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)
            .padding(.horizontal, AureaTheme.Spacing.xl)
            .padding(.vertical, AureaTheme.Spacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: AureaTheme.Radius.pill)
                    .stroke(color, lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.3), radius: AureaTheme.Shadows.subtleGlowRadius, x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Legacy Aliases

typealias NeonButton = AureaButton
typealias NeonOutlineButton = AureaOutlineButton

#Preview {
    VStack(spacing: 20) {
        AureaButton(title: "START SESSION", icon: "play.fill", color: .aureaPrimary) {}
        AureaButton(title: "SCAN", icon: "camera.fill") {}
        AureaButton(title: "Quick", isCompact: true) {}
        AureaOutlineButton(title: "VIEW DETAILS", icon: "chevron.right") {}
    }
    .padding()
    .background(Color.aureaVoid)
}
