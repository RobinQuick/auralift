import SwiftUI

// MARK: - ProgramExerciseRow

/// A row displaying a prescribed exercise with targets, SWAP button,
/// and expandable "Why" explanation.
struct ProgramExerciseRow: View {
    let programExercise: ProgramExercise
    let onSwap: () -> Void

    @State private var showWhy = false

    var body: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            // Main row
            HStack(spacing: AuraTheme.Spacing.sm) {
                // Order badge
                Text("\(programExercise.exerciseOrder + 1)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.auraBlack)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(priorityColor))

                // Exercise info
                VStack(alignment: .leading, spacing: 2) {
                    Text(programExercise.exerciseName.uppercased())
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)
                        .lineLimit(1)

                    HStack(spacing: AuraTheme.Spacing.sm) {
                        targetBadge(
                            icon: "scalemass.fill",
                            text: "\(Int(programExercise.targetWeightKg)) kg"
                        )
                        targetBadge(
                            icon: "repeat",
                            text: "\(programExercise.targetSets)x\(programExercise.targetReps)"
                        )
                        targetBadge(
                            icon: "gauge.medium",
                            text: "RPE \(String(format: "%.0f", programExercise.targetRPE))"
                        )
                    }
                }

                Spacer()

                // Swap button
                Button(action: onSwap) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyberOrange)
                        .frame(width: 32, height: 32)
                        .background(Color.cyberOrange.opacity(0.15))
                        .cornerRadius(AuraTheme.Radius.small)
                }

                // Why chevron
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showWhy.toggle()
                    }
                } label: {
                    Image(systemName: showWhy ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.auraTextSecondary)
                }
            }

            // Expandable "Why" section
            if showWhy {
                whySection
            }

            // Completion status
            if programExercise.isCompleted {
                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.neonGreen)

                    Text("Completed — \(Int(programExercise.actualReps)) reps @ \(Int(programExercise.actualWeightKg)) kg")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.neonGreen)
                }
            }
        }
        .darkCard()
    }

    // MARK: - Why Section

    private var whySection: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
            if let why = programExercise.whyMessage, !why.isEmpty {
                HStack(alignment: .top, spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.neonGold)

                    Text(why)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
            }

            if let priority = programExercise.priorityReason, !priority.isEmpty {
                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyberOrange)

                    Text(priority)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.cyberOrange)
                }
            }

            // Tempo + rest
            HStack(spacing: AuraTheme.Spacing.md) {
                if let tempo = programExercise.tempoDescription {
                    Label(tempo, systemImage: "metronome.fill")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.auraTextDisabled)
                }

                Label("\(programExercise.restSeconds)s rest", systemImage: "clock.fill")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.auraTextDisabled)
            }
        }
        .padding(.leading, 36)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Target Badge

    private func targetBadge(icon: String, text: String) -> some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundColor(.auraTextSecondary)
    }

    // MARK: - Priority Color

    private var priorityColor: Color {
        programExercise.priorityReason != nil ? .cyberOrange : .neonBlue
    }
}
