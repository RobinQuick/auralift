import SwiftUI

/// Displays biometric recovery data including HRV, sleep metrics, resting heart rate,
/// active energy, and menstrual cycle phase with component readiness scores.
struct BioMetricsView: View {
    @ObservedObject var viewModel: RecoveryViewModel

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            // MARK: - Component Scores
            componentScoresSection

            // MARK: - HRV & Heart Rate
            HStack(spacing: AuraTheme.Spacing.md) {
                metricCard(
                    icon: "heart.text.square.fill",
                    label: "HRV",
                    value: viewModel.hrvValue > 0 ? "\(Int(viewModel.hrvValue))" : "--",
                    unit: "ms",
                    accent: scoreColor(viewModel.hrvScore),
                    score: viewModel.hrvScore
                )
                metricCard(
                    icon: "heart.fill",
                    label: "Resting HR",
                    value: viewModel.restingHeartRate > 0 ? "\(Int(viewModel.restingHeartRate))" : "--",
                    unit: "bpm",
                    accent: scoreColor(viewModel.restingHRScore),
                    score: viewModel.restingHRScore
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            // MARK: - Sleep
            HStack(spacing: AuraTheme.Spacing.md) {
                metricCard(
                    icon: "moon.fill",
                    label: "Sleep",
                    value: viewModel.sleepHours > 0 ? String(format: "%.1f", viewModel.sleepHours) : "--",
                    unit: "hrs",
                    accent: scoreColor(viewModel.sleepScore),
                    score: viewModel.sleepScore
                )
                metricCard(
                    icon: "flame.fill",
                    label: "Active",
                    value: viewModel.activeEnergy > 0 ? "\(Int(viewModel.activeEnergy))" : "--",
                    unit: "kcal",
                    accent: .cyberOrange,
                    score: nil
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            // MARK: - Cycle Phase
            if let phase = viewModel.cyclePhase {
                cyclePhaseCard(phase)
                    .padding(.horizontal, AuraTheme.Spacing.lg)
            }

            // MARK: - HRV Baseline
            if viewModel.hrvBaseline > 0 {
                hrvBaselineCard
                    .padding(.horizontal, AuraTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Component Scores

    private var componentScoresSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Text("READINESS BREAKDOWN")
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.auraTextSecondary)

            HStack(spacing: AuraTheme.Spacing.md) {
                scoreRing(label: "HRV", score: viewModel.hrvScore, color: scoreColor(viewModel.hrvScore))
                scoreRing(label: "Sleep", score: viewModel.sleepScore, color: scoreColor(viewModel.sleepScore))
                scoreRing(label: "HR", score: viewModel.restingHRScore, color: scoreColor(viewModel.restingHRScore))
                scoreRing(label: "Muscle", score: viewModel.muscleRecoveryAverage, color: scoreColor(viewModel.muscleRecoveryAverage))
            }
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func scoreRing(label: String, score: Double, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(Color.auraSurface, lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: min(1.0, score / 100.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.4), radius: 3)

                Text("\(Int(score))")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(color)
            }

            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Metric Card

    private func metricCard(
        icon: String,
        label: String,
        value: String,
        unit: String,
        accent: Color,
        score: Double?
    ) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(accent)

            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            HStack(alignment: .lastTextBaseline, spacing: AuraTheme.Spacing.xxs) {
                Text(value)
                    .font(AuraTheme.Fonts.statValue(22))
                    .foregroundColor(.auraTextPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
            }

            if let score = score {
                // Score bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                            .fill(Color.auraSurface)
                            .frame(height: 3)

                        RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                            .fill(accent)
                            .frame(width: geometry.size.width * min(1.0, score / 100.0), height: 3)
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .neonGlow(color: accent, radius: AuraTheme.Shadows.subtleGlowRadius)
    }

    // MARK: - Cycle Phase Card

    private func cyclePhaseCard(_ phase: CyclePhase) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "circle.hexagongrid.fill")
                    .foregroundColor(.neonPurple)
                Text("CYCLE SYNC")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
                Spacer()
                Text(phase.displayName)
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonPurple)
            }

            Text(phase.trainingGuidance)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AuraTheme.Spacing.lg) {
                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("Intensity")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    Text("\(Int(phase.intensityModifier * 100))%")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(phase.intensityModifier >= 1.0 ? .neonGreen : .cyberOrange)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("Volume")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    Text("\(Int(phase.volumeModifier * 100))%")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(phase.volumeModifier >= 1.0 ? .neonGreen : .cyberOrange)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("Phase")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    Text(phase.dayRange)
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(.neonPurple)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .darkCard()
        .neonGlow(color: .neonPurple, radius: AuraTheme.Shadows.subtleGlowRadius)
    }

    // MARK: - HRV Baseline

    private var hrvBaselineCard: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.neonGreen)
                Text("HRV TREND")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
            }

            HStack(spacing: AuraTheme.Spacing.xl) {
                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("Current")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    Text("\(Int(viewModel.hrvValue)) ms")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(viewModel.hrvValue >= viewModel.hrvBaseline ? .neonGreen : .neonRed)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("14-Day Avg")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    Text("\(Int(viewModel.hrvBaseline)) ms")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(.auraTextSecondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("Delta")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                    let delta = viewModel.hrvBaseline > 0
                        ? Int(((viewModel.hrvValue - viewModel.hrvBaseline) / viewModel.hrvBaseline) * 100)
                        : 0
                    let sign = delta >= 0 ? "+" : ""
                    Text("\(sign)\(delta)%")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(delta >= 0 ? .neonGreen : .neonRed)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .darkCard()
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .neonGreen }
        if score >= 55 { return .cyberOrange }
        return .neonRed
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        BioMetricsView(viewModel: RecoveryViewModel(
            context: PersistenceController.preview.container.viewContext
        ))
    }
    .auraBackground()
}
