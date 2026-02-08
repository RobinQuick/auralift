import SwiftUI

// MARK: - ExerciseSwapSheet

/// Bottom sheet showing up to 3 alternative exercises for a swap.
struct ExerciseSwapSheet: View {
    let suggestions: [ExerciseSwapSuggestion]
    let currentExerciseName: String
    let onSelect: (ExerciseSwapSuggestion) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AuraTheme.Spacing.lg) {
                // Header
                VStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28))
                        .foregroundColor(.cyberOrange)

                    Text("SWAP \(currentExerciseName.uppercased())")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    Text("Choose an alternative exercise")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
                .padding(.top, AuraTheme.Spacing.lg)

                // Suggestion cards
                ForEach(suggestions) { suggestion in
                    suggestionCard(suggestion)
                }

                Spacer()

                // Cancel
                Button("Keep Current Exercise") {
                    dismiss()
                }
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
                .padding(.bottom, AuraTheme.Spacing.xl)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .auraBackground()
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Suggestion Card

    private func suggestionCard(_ suggestion: ExerciseSwapSuggestion) -> some View {
        Button {
            onSelect(suggestion)
        } label: {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                // Top row: name + morpho badge
                HStack {
                    Text(suggestion.exercise.name.uppercased())
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)
                        .lineLimit(1)

                    Spacer()

                    morphoFitBadge(suggestion.morphoFit)
                }

                // Targets
                HStack(spacing: AuraTheme.Spacing.md) {
                    Label(
                        "\(Int(suggestion.suggestedWeight)) kg",
                        systemImage: "scalemass.fill"
                    )
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.neonBlue)

                    Label(
                        suggestion.suggestedReps,
                        systemImage: "repeat"
                    )
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.neonBlue)

                    if let eq = suggestion.exercise.equipmentType {
                        Text(eq.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.auraTextDisabled)
                    }
                }

                // Why message
                Text(suggestion.whyMessage)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .lineLimit(2)
            }
            .darkCard()
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(Color.cyberOrange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Morpho Fit Badge

    private func morphoFitBadge(_ fit: ExerciseSwapSuggestion.MorphoFit) -> some View {
        let color: Color = {
            switch fit {
            case .ideal: return .neonGreen
            case .good: return .neonBlue
            case .acceptable: return .cyberOrange
            }
        }()

        return Text(fit.displayName)
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundColor(.auraBlack)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color))
    }
}
