import SwiftUI

/// Supplement recommendations view with evidence-based stack, priority indicators,
/// and category grouping — driven by SupplementAdvisor.
struct SupplementView: View {
    @ObservedObject var viewModel: NutritionViewModel

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            if viewModel.supplements.isEmpty {
                emptyState
            } else {
                // MARK: - Summary
                stackSummary

                // MARK: - By Priority
                supplementSection(
                    title: "ESSENTIAL",
                    supplements: viewModel.supplements.filter { $0.priority == .essential },
                    accentColor: .neonGreen
                )

                supplementSection(
                    title: "RECOMMENDED",
                    supplements: viewModel.supplements.filter { $0.priority == .recommended },
                    accentColor: .neonBlue
                )

                supplementSection(
                    title: "OPTIONAL",
                    supplements: viewModel.supplements.filter { $0.priority == .optional },
                    accentColor: .auraTextSecondary
                )

                // Disclaimer
                Text("Recommendations based on peer-reviewed research.\nConsult a healthcare provider before use.")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
                    .multilineTextAlignment(.center)
                    .padding(.top, AuraTheme.Spacing.md)
            }
        }
    }

    // MARK: - Stack Summary

    private var stackSummary: some View {
        HStack(spacing: AuraTheme.Spacing.lg) {
            summaryBadge(
                count: viewModel.supplements.filter { $0.priority == .essential }.count,
                label: "Essential",
                color: .neonGreen
            )
            summaryBadge(
                count: viewModel.supplements.filter { $0.priority == .recommended }.count,
                label: "Targeted",
                color: .neonBlue
            )
            summaryBadge(
                count: viewModel.supplements.filter { $0.priority == .optional }.count,
                label: "Optional",
                color: .auraTextSecondary
            )
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Supplement stack: \(viewModel.supplements.filter { $0.priority == .essential }.count) essential, \(viewModel.supplements.filter { $0.priority == .recommended }.count) targeted, \(viewModel.supplements.filter { $0.priority == .optional }.count) optional")
    }

    private func summaryBadge(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            Text("\(count)")
                .font(AuraTheme.Fonts.statValue(22))
                .foregroundColor(color)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label) supplements")
    }

    // MARK: - Supplement Section

    private func supplementSection(title: String, supplements: [SupplementRecommendation], accentColor: Color) -> some View {
        guard !supplements.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                Text(title)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(accentColor)
                    .padding(.horizontal, AuraTheme.Spacing.lg)

                ForEach(supplements) { supplement in
                    supplementRow(supplement, accentColor: accentColor)
                }
            }
        )
    }

    private func supplementRow(_ supplement: SupplementRecommendation, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.md) {
                // Icon
                Image(systemName: supplement.icon)
                    .font(.system(size: 22))
                    .foregroundColor(accentColor)
                    .frame(width: 30)

                // Name + dosage
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    Text(supplement.name)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    HStack(spacing: AuraTheme.Spacing.sm) {
                        Label(supplement.dosage, systemImage: "scalemass")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)

                        Label(supplement.timing, systemImage: "clock")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }
                }

                Spacer()

                // Evidence badge
                Text(supplement.evidenceLevel.displayBadge)
                    .font(AuraTheme.Fonts.mono(14))
                    .foregroundColor(evidenceColor(supplement.evidenceLevel))
                    .frame(width: 28, height: 28)
                    .background(evidenceColor(supplement.evidenceLevel).opacity(0.15))
                    .cornerRadius(AuraTheme.Radius.small)
            }

            // Reason
            Text(supplement.reason)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            // Category badge
            Text(supplement.category.rawValue)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
                .padding(.horizontal, AuraTheme.Spacing.sm)
                .padding(.vertical, 2)
                .background(Color.auraSurfaceElevated)
                .cornerRadius(AuraTheme.Radius.pill)
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(supplement.name), \(supplement.dosage), \(supplement.timing). \(supplement.reason). Evidence level \(supplement.evidenceLevel.displayBadge)")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "pills.fill")
                .font(.system(size: 50))
                .foregroundColor(.auraTextDisabled)
            Text("No Recommendations Yet")
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.auraTextSecondary)
            Text("Complete your profile and a workout\nto get personalized supplement advice")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AuraTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func evidenceColor(_ level: EvidenceLevel) -> Color {
        switch level {
        case .strong:   return .neonGreen
        case .moderate: return .neonBlue
        case .emerging: return .cyberOrange
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        SupplementView(viewModel: NutritionViewModel(
            context: PersistenceController.preview.container.viewContext
        ))
    }
    .auraBackground()
}
