import SwiftUI

/// Neon-bordered card component with glow effect.
struct GlowCard<Content: View>: View {
    var glowColor: Color = .neonBlue
    var cornerRadius: CGFloat = AuraTheme.Radius.medium
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: glowColor.opacity(0.2), radius: 8, x: 0, y: 0)
    }
}

/// Stat card variant showing a label and value
struct StatCard: View {
    let label: String
    let value: String
    var unit: String = ""
    var color: Color = .neonBlue
    var icon: String? = nil

    var body: some View {
        GlowCard(glowColor: color) {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(color)
                    }
                    Text(label.uppercased())
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(AuraTheme.Fonts.statValue(28))
                        .foregroundColor(.auraTextPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        GlowCard(glowColor: .cyberOrange) {
            Text("Custom Content")
                .foregroundColor(.white)
        }

        StatCard(label: "Total Volume", value: "12,450", unit: "kg", color: .neonBlue, icon: "scalemass.fill")
        StatCard(label: "Form Score", value: "94", unit: "%", color: .neonGreen, icon: "checkmark.seal.fill")
    }
    .padding()
    .background(Color.auraBlack)
}
