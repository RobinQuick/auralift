import SwiftUI
import CoreData

/// Displays completed set data with velocity tracking, form scores, and RPE.
/// Accepts completed sets from WorkoutViewModel.
struct SetTrackerView: View {
    let completedSets: [SetSummary]
    let exerciseName: String

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            // MARK: - Header
            VStack(spacing: AuraTheme.Spacing.xs) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32))
                    .cyberpunkText(color: .neonBlue)

                Text("SET TRACKER")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: .neonBlue)

                if !exerciseName.isEmpty {
                    Text(exerciseName.uppercased())
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
            }
            .padding(.top, AuraTheme.Spacing.xl)

            if completedSets.isEmpty {
                emptyState
            } else {
                // MARK: - Set List
                VStack(spacing: AuraTheme.Spacing.md) {
                    // Column headers
                    HStack {
                        Text("SET")
                            .frame(width: 36, alignment: .leading)
                        Text("REPS")
                            .frame(width: 40, alignment: .center)
                        Text("KG")
                            .frame(width: 50, alignment: .center)
                        Text("m/s")
                            .frame(width: 50, alignment: .center)
                        Text("FORM")
                            .frame(width: 40, alignment: .center)
                        Text("RPE")
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .padding(.horizontal, AuraTheme.Spacing.lg)

                    ForEach(completedSets) { entry in
                        setRow(entry)
                    }
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)

                // MARK: - Velocity Trend
                if completedSets.count >= 2 {
                    velocityTrendView
                        .padding(.horizontal, AuraTheme.Spacing.lg)
                }
            }

            Spacer()
        }
        .auraBackground()
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.auraTextDisabled)

            Text("Complete a set to see tracking data")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
        }
        .padding(.top, AuraTheme.Spacing.xxl)
    }

    // MARK: - Set Row

    private func setRow(_ entry: SetSummary) -> some View {
        HStack {
            Text("#\(entry.setNumber)")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.neonBlue)
                .frame(width: 36, alignment: .leading)

            Text("\(entry.reps)")
                .font(AuraTheme.Fonts.statValue(22))
                .foregroundColor(.auraTextPrimary)
                .frame(width: 40, alignment: .center)

            Text(String(format: "%.1f", entry.weightKg))
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.auraTextPrimary)
                .frame(width: 50, alignment: .center)

            velocityBadge(entry.averageVelocity)
                .frame(width: 50, alignment: .center)

            Text("\(Int(entry.averageFormScore))%")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(formColor(entry.averageFormScore))
                .frame(width: 40, alignment: .center)

            Spacer()

            Text(String(format: "%.0f", entry.rpe))
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(rpeColor(entry.rpe))
        }
        .darkCard()
        .neonGlow(color: velocityColor(entry.averageVelocity), radius: AuraTheme.Shadows.subtleGlowRadius)
    }

    // MARK: - Velocity Trend

    private var velocityTrendView: some View {
        let velocities = completedSets.map(\.averageVelocity)
        let firstVel = velocities.first ?? 0
        let lastVel = velocities.last ?? 0
        let trend = firstVel > 0 ? (firstVel - lastVel) / firstVel : 0

        return VStack(spacing: AuraTheme.Spacing.sm) {
            HStack {
                Text("VELOCITY TREND")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)

                Spacer()

                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: trend > 0.15 ? "arrow.down.right" : trend > 0.05 ? "arrow.right" : "arrow.up.right")
                        .foregroundColor(trend > 0.15 ? .neonRed : trend > 0.05 ? .cyberOrange : .neonGreen)

                    Text(String(format: "%.0f%% loss", trend * 100))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(trend > 0.15 ? .neonRed : trend > 0.05 ? .cyberOrange : .neonGreen)
                }
            }

            // Simple velocity bar chart
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(velocities.enumerated()), id: \.offset) { index, velocity in
                    let maxVel = velocities.max() ?? 1
                    let height = maxVel > 0 ? CGFloat(velocity / maxVel) * 60 : 0

                    VStack(spacing: 2) {
                        Text(String(format: "%.2f", velocity))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.auraTextSecondary)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(velocityColor(velocity))
                            .frame(height: max(4, height))

                        Text("S\(index + 1)")
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.auraTextDisabled)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 90)
        }
        .darkCard()
    }

    // MARK: - Velocity Badge

    private func velocityBadge(_ velocity: Double) -> some View {
        Text(String(format: "%.2f", velocity))
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundColor(.auraBlack)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(velocityColor(velocity))
            )
    }

    private func velocityColor(_ velocity: Double) -> Color {
        if velocity >= 0.65 { return .neonGreen }
        if velocity >= 0.50 { return .cyberOrange }
        if velocity > 0 { return .neonRed }
        return .auraTextDisabled
    }

    private func formColor(_ score: Double) -> Color {
        if score >= 90 { return .neonGreen }
        if score >= 70 { return .cyberOrange }
        return .neonRed
    }

    private func rpeColor(_ rpe: Double) -> Color {
        if rpe >= 9 { return .neonRed }
        if rpe >= 8 { return .cyberOrange }
        return .auraTextSecondary
    }
}

// MARK: - Preview

#Preview {
    SetTrackerView(
        completedSets: [
            SetSummary(setNumber: 1, reps: 10, weightKg: 80.0, averageFormScore: 92,
                       averageVelocity: 0.72, peakVelocity: 0.85, velocityLossPercent: 0,
                       romDegrees: 95, barPathDeviation: 0.1, eccentricDuration: 2.0,
                       concentricDuration: 1.2, rpe: 6.5, xpEarned: 150,
                       autoStopped: false, velocityZone: .strength),
            SetSummary(setNumber: 2, reps: 9, weightKg: 80.0, averageFormScore: 88,
                       averageVelocity: 0.65, peakVelocity: 0.78, velocityLossPercent: 0.10,
                       romDegrees: 93, barPathDeviation: 0.12, eccentricDuration: 2.1,
                       concentricDuration: 1.4, rpe: 7.5, xpEarned: 120,
                       autoStopped: false, velocityZone: .strength),
            SetSummary(setNumber: 3, reps: 8, weightKg: 80.0, averageFormScore: 85,
                       averageVelocity: 0.58, peakVelocity: 0.70, velocityLossPercent: 0.19,
                       romDegrees: 90, barPathDeviation: 0.15, eccentricDuration: 2.3,
                       concentricDuration: 1.6, rpe: 8.5, xpEarned: 100,
                       autoStopped: false, velocityZone: .strength),
        ],
        exerciseName: "Barbell Bench Press"
    )
}
