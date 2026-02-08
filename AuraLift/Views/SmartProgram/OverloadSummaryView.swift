import SwiftUI

// MARK: - OverloadSummaryView

/// Post-week summary showing weight adjustment decisions with explanations.
struct OverloadSummaryView: View {
    let decisions: [OverloadDecision]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: AuraTheme.Spacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 36))
                            .foregroundColor(.neonGreen)

                        Text("WEEK COMPLETE")
                            .font(AuraTheme.Fonts.title())
                            .cyberpunkText(color: .neonBlue)

                        Text("Here's how your weights will adjust for next week")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AuraTheme.Spacing.xl)

                    // Summary stats
                    summaryStats

                    // Decision list
                    ForEach(decisions) { decision in
                        decisionRow(decision)
                    }

                    // Done button
                    NeonButton(title: "GOT IT", icon: "checkmark", color: .neonBlue) {
                        dismiss()
                    }
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                    .padding(.bottom, AuraTheme.Spacing.xxl)
                }
            }
            .auraBackground()
        }
    }

    // MARK: - Summary Stats

    private var summaryStats: some View {
        HStack(spacing: AuraTheme.Spacing.lg) {
            let increases = decisions.filter(\.isIncrease).count
            let maintains = decisions.filter(\.isMaintain).count
            let decreases = decisions.filter(\.isDecrease).count

            miniStat(value: "\(increases)", label: "INCREASE", color: .neonGreen)
            miniStat(value: "\(maintains)", label: "MAINTAIN", color: .neonBlue)
            miniStat(value: "\(decreases)", label: "REDUCE", color: .cyberOrange)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func miniStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text(value)
                .font(AuraTheme.Fonts.statValue(24))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
    }

    // MARK: - Decision Row

    private func decisionRow(_ decision: OverloadDecision) -> some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            // Arrow indicator
            Image(systemName: arrowIcon(decision))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(arrowColor(decision))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(decision.exerciseName.uppercased())
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
                    .lineLimit(1)

                Text(decision.whyMessage)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .lineLimit(2)
            }

            Spacer()

            // Weight change
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kg", decision.newWeight))
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.auraTextPrimary)

                if decision.weightChange != 0 {
                    Text(String(format: "%+.1f", decision.weightChange))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(arrowColor(decision))
                }
            }
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Helpers

    private func arrowIcon(_ decision: OverloadDecision) -> String {
        if decision.isIncrease { return "arrow.up.circle.fill" }
        if decision.isDecrease { return "arrow.down.circle.fill" }
        return "equal.circle.fill"
    }

    private func arrowColor(_ decision: OverloadDecision) -> Color {
        if decision.isIncrease { return .neonGreen }
        if decision.isDecrease { return .cyberOrange }
        return .neonBlue
    }
}
