import SwiftUI

/// Cyberpunk-styled button with neon glow effect.
struct NeonButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .neonBlue
    var isCompact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: isCompact ? 14 : 18, weight: .bold))
                }
                Text(title)
                    .font(isCompact ? AuraTheme.Fonts.caption() : AuraTheme.Fonts.subheading())
                    .fontWeight(.bold)
            }
            .foregroundColor(.auraBlack)
            .padding(.horizontal, isCompact ? AuraTheme.Spacing.lg : AuraTheme.Spacing.xl)
            .padding(.vertical, isCompact ? AuraTheme.Spacing.sm : AuraTheme.Spacing.md)
            .background(color)
            .cornerRadius(AuraTheme.Radius.pill)
            .shadow(color: color.opacity(0.6), radius: AuraTheme.Shadows.glowRadius, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

/// Outlined variant of NeonButton
struct NeonOutlineButton: View {
    let title: String
    var icon: String? = nil
    var color: Color = .neonBlue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(AuraTheme.Fonts.subheading())
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)
            .padding(.horizontal, AuraTheme.Spacing.xl)
            .padding(.vertical, AuraTheme.Spacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                    .stroke(color, lineWidth: 1.5)
            )
            .shadow(color: color.opacity(0.3), radius: AuraTheme.Shadows.subtleGlowRadius, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        NeonButton(title: "START WORKOUT", icon: "play.fill", color: .cyberOrange) {}
        NeonButton(title: "SCAN", icon: "camera.fill") {}
        NeonButton(title: "Quick", isCompact: true) {}
        NeonOutlineButton(title: "VIEW DETAILS", icon: "chevron.right") {}
    }
    .padding()
    .background(Color.auraBlack)
}
