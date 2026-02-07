import SwiftUI

/// Horizontal progress bar that displays XP advancement toward the next rank tier.
/// Features a neon glow effect on the filled portion.
struct XPProgressBar: View {
    let currentXP: Int64
    let requiredXP: Int64
    let tier: String

    private var progress: Double {
        guard requiredXP > 0 else { return 0 }
        return min(Double(currentXP) / Double(requiredXP), 1.0)
    }

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            // MARK: - Labels
            HStack {
                Text(tier.uppercased())
                    .font(AuraTheme.Fonts.caption())
                    .cyberpunkText(color: .neonBlue)

                Spacer()

                Text("\(currentXP) / \(requiredXP) XP")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.auraTextSecondary)
            }

            // MARK: - Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                        .fill(Color.auraSurfaceElevated)
                        .frame(height: 12)

                    // Filled portion with neon glow
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                        .fill(
                            LinearGradient(
                                colors: [.neonBlue, .neonBlue.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                        .shadow(color: .neonBlue.opacity(0.8), radius: 6, x: 0, y: 0)
                        .shadow(color: .neonBlue.opacity(0.4), radius: 12, x: 0, y: 0)
                }
            }
            .frame(height: 12)

            // MARK: - Percentage
            HStack {
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .padding(AuraTheme.Spacing.lg)
        .background(Color.auraSurface)
        .cornerRadius(AuraTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(Color.neonBlue.opacity(0.3), lineWidth: 0.5)
        )
    }
}

// MARK: - Preview

#Preview {
    XPProgressBar(currentXP: 4_200, requiredXP: 10_000, tier: "Gold")
        .padding()
        .background(Color.auraBlack)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
