import SwiftUI

/// Gold-bordered card component with glow effect.
struct AureaGlowCard<Content: View>: View {
    var glowColor: Color = .aureaPrimary
    var cornerRadius: CGFloat = AureaTheme.Radius.medium
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(AureaTheme.Spacing.lg)
            .background(Color.aureaSurfaceElevated)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(glowColor.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: glowColor.opacity(0.2), radius: 8, x: 0, y: 0)
    }
}

// MARK: - Legacy Alias

typealias GlowCard = AureaGlowCard

/// Stat card variant showing a label and value
struct StatCard: View {
    let label: String
    let value: String
    var unit: String = ""
    var color: Color = .aureaPrimary
    var icon: String? = nil

    var body: some View {
        AureaGlowCard(glowColor: color) {
            VStack(alignment: .leading, spacing: AureaTheme.Spacing.sm) {
                HStack {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(color)
                    }
                    Text(label.uppercased())
                        .font(AureaTheme.Fonts.caption())
                        .foregroundColor(.aureaTextSecondary)
                }

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(AureaTheme.Fonts.statValue(28))
                        .foregroundColor(.aureaTextPrimary)
                    if !unit.isEmpty {
                        Text(unit)
                            .font(AureaTheme.Fonts.caption())
                            .foregroundColor(.aureaTextSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)\(unit.isEmpty ? "" : " \(unit)")")
    }
}

#Preview {
    VStack(spacing: 16) {
        AureaGlowCard(glowColor: .aureaSecondary) {
            Text("Custom Content")
                .foregroundColor(.white)
        }

        StatCard(label: "Total Volume", value: "12,450", unit: "kg", color: .aureaPrimary, icon: "scalemass.fill")
        StatCard(label: "Form Score", value: "94", unit: "%", color: .aureaSuccess, icon: "checkmark.seal.fill")
    }
    .padding()
    .background(Color.aureaVoid)
}
