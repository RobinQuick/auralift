import SwiftUI

/// Displays body composition stats and a radar chart comparing current proportions
/// to the Greek ideal (Golden Ratio). Shows priority muscle groups to train.
struct BodyStatsView: View {
    @ObservedObject var viewModel: NutritionViewModel

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            // MARK: - Golden Ratio Score
            if let result = viewModel.goldenRatioResult {
                goldenRatioHeader(result)
                radarChart(result)
                deviationsSection(result)

                if !result.priorityMuscleGroups.isEmpty {
                    priorityMusclesCard(result)
                }

                if !result.actionableSummary.isEmpty {
                    actionCard(result.actionableSummary)
                }
            } else {
                emptyState
            }

            // MARK: - Body Composition Stats
            bodyCompositionCards
        }
    }

    // MARK: - Golden Ratio Header

    private func goldenRatioHeader(_ result: GoldenRatioResult) -> some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Color.auraSurfaceElevated, lineWidth: 10)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: result.overallScore / 100.0)
                    .stroke(
                        scoreColor(result.overallScore),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: scoreColor(result.overallScore).opacity(0.5), radius: 6)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("\(Int(result.overallScore))")
                        .font(AuraTheme.Fonts.statValue(28))
                        .foregroundColor(scoreColor(result.overallScore))
                    Text("GREEK")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
            }

            Text("Golden Ratio Score")
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.neonGold)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Golden Ratio score: \(Int(result.overallScore)) out of 100")
    }

    // MARK: - Radar Chart

    private func radarChart(_ result: GoldenRatioResult) -> some View {
        let deviations = result.deviations

        return ZStack {
            // Background grid
            ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                radarPolygon(values: Array(repeating: scale, count: deviations.count))
                    .stroke(Color.auraSurfaceElevated, lineWidth: 1)
            }

            // Ideal (1.0 = 100% match)
            radarPolygon(values: Array(repeating: 1.0, count: deviations.count))
                .stroke(Color.neonGold.opacity(0.3), lineWidth: 2)
                .shadow(color: .neonGold.opacity(0.2), radius: 4)

            // Actual scores
            let scores = deviations.map { max(0, min(1.0, 1.0 - $0.deviationPercent)) }
            radarPolygon(values: scores)
                .fill(Color.neonBlue.opacity(0.15))

            radarPolygon(values: scores)
                .stroke(Color.neonBlue, lineWidth: 2)
                .shadow(color: .neonBlue.opacity(0.5), radius: 4)

            // Labels
            ForEach(0..<deviations.count, id: \.self) { index in
                let angle = angleForIndex(index, total: deviations.count)
                let labelRadius: CGFloat = 95
                let x = cos(angle) * labelRadius
                let y = sin(angle) * labelRadius

                Text(shortLabel(deviations[index].ratioName))
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .offset(x: x, y: y)
            }
        }
        .frame(width: 220, height: 220)
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Radar chart showing body proportion ratios compared to the ideal")
    }

    private func radarPolygon(values: [Double]) -> some Shape {
        RadarShape(values: values)
    }

    private func angleForIndex(_ index: Int, total: Int) -> CGFloat {
        let fraction = CGFloat(index) / CGFloat(total)
        return fraction * 2 * .pi - .pi / 2
    }

    private func shortLabel(_ name: String) -> String {
        if name.contains("V-Taper") { return "V-Taper" }
        if name.contains("Golden") { return "S/W" }
        if name.contains("Da Vinci") { return "Span" }
        if name.contains("Body Fat") { return "BF%" }
        return String(name.prefix(8))
    }

    // MARK: - Deviations

    private func deviationsSection(_ result: GoldenRatioResult) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            ForEach(result.deviations, id: \.ratioName) { dev in
                HStack(spacing: AuraTheme.Spacing.md) {
                    // Status dot
                    Circle()
                        .fill(statusColor(dev.status))
                        .frame(width: 10, height: 10)
                        .shadow(color: statusColor(dev.status).opacity(0.5), radius: 3)

                    VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                        Text(dev.ratioName)
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.auraTextPrimary)

                        HStack(spacing: AuraTheme.Spacing.sm) {
                            Text("Actual: \(String(format: "%.2f", dev.actualValue))")
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.auraTextSecondary)
                            Text("Ideal: \(String(format: "%.2f", dev.idealValue))")
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.neonGold)
                        }
                    }

                    Spacer()

                    Text(dev.status.rawValue)
                        .font(AuraTheme.Fonts.mono(12))
                        .foregroundColor(statusColor(dev.status))
                }
                .darkCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(dev.ratioName): actual \(String(format: "%.2f", dev.actualValue)), ideal \(String(format: "%.2f", dev.idealValue)), status \(dev.status.rawValue)")
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Priority Muscles

    private func priorityMusclesCard(_ result: GoldenRatioResult) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "target")
                    .foregroundColor(.cyberOrange)
                Text("PRIORITY MUSCLES")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
            }

            HStack(spacing: AuraTheme.Spacing.sm) {
                ForEach(result.priorityMuscleGroups, id: \.self) { muscle in
                    Text(muscle)
                        .font(AuraTheme.Fonts.mono(12))
                        .foregroundColor(.cyberOrange)
                        .padding(.horizontal, AuraTheme.Spacing.sm)
                        .padding(.vertical, AuraTheme.Spacing.xxs)
                        .background(Color.cyberOrange.opacity(0.15))
                        .cornerRadius(AuraTheme.Radius.pill)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Priority muscles: \(result.priorityMuscleGroups.joined(separator: ", "))")
    }

    // MARK: - Action Card

    private func actionCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.neonGold)
                Text("20/80 ACTION")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
            }

            Text(summary)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkCard()
        .neonGlow(color: .neonGold, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Action recommendation: \(summary)")
    }

    // MARK: - Body Composition

    private var bodyCompositionCards: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.md) {
                statCard(label: "Weight", value: viewModel.weightKg > 0 ? String(format: "%.1f", viewModel.weightKg) : "--", unit: "kg", icon: "scalemass.fill", color: .neonBlue)
                statCard(label: "Body Fat", value: viewModel.bodyFatPercent > 0 ? String(format: "%.1f", viewModel.bodyFatPercent) : "--", unit: "%", icon: "percent", color: .cyberOrange)
            }

            HStack(spacing: AuraTheme.Spacing.md) {
                statCard(label: "Height", value: viewModel.heightCm > 0 ? String(format: "%.0f", viewModel.heightCm) : "--", unit: "cm", icon: "ruler.fill", color: .neonGreen)
                statCard(label: "Lean Mass", value: viewModel.leanMassKg > 0 ? String(format: "%.1f", viewModel.leanMassKg) : "--", unit: "kg", icon: "figure.strengthtraining.traditional", color: .neonPurple)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func statCard(label: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
            HStack(alignment: .lastTextBaseline, spacing: AuraTheme.Spacing.xxs) {
                Text(value)
                    .font(AuraTheme.Fonts.statValue(20))
                    .foregroundColor(.auraTextPrimary)
                Text(unit)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "figure.arms.open")
                .font(.system(size: 50))
                .foregroundColor(.auraTextDisabled)
            Text("No Morpho Scan Data")
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.auraTextSecondary)
            Text("Complete a body scan to see your\nGolden Ratio analysis")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, AuraTheme.Spacing.xxl)
    }

    // MARK: - Helpers

    private func scoreColor(_ score: Double) -> Color {
        if score >= 80 { return .neonGold }
        if score >= 60 { return .neonGreen }
        if score >= 40 { return .cyberOrange }
        return .neonRed
    }

    private func statusColor(_ status: GoldenRatioStatus) -> Color {
        switch status {
        case .ideal:     return .neonGold
        case .close:     return .neonGreen
        case .needsWork: return .cyberOrange
        }
    }
}

// MARK: - Radar Shape

struct RadarShape: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        guard values.count >= 3 else { return Path() }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * 0.75

        var path = Path()
        for (index, value) in values.enumerated() {
            let angle = CGFloat(index) / CGFloat(values.count) * 2 * .pi - .pi / 2
            let r = CGFloat(value) * radius
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()

        return path
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        BodyStatsView(viewModel: NutritionViewModel(
            context: PersistenceController.preview.container.viewContext
        ))
    }
    .auraBackground()
}
