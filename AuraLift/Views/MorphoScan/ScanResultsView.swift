import SwiftUI
import CoreData

/// Displays limb ratio results, exercise risk profile, and biomechanical
/// summary from a completed MorphoScan.
struct ScanResultsView: View {
    @Environment(\.dismiss) private var dismiss

    let measurements: SegmentMeasurements
    let morphotype: Morphotype
    let riskMap: [UUID: ExerciseRisk]
    let exercises: [Exercise]
    let summary: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    // Header
                    header
                        .padding(.top, AuraTheme.Spacing.xl)

                    // Morphotype badge
                    morphotypeBadge
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // Ratio cards
                    ratioCardsSection
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // Exercise risk profile
                    riskProfileSection
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // Biomechanical summary
                    summaryCard
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // Done button
                    NeonButton(title: "DONE", icon: "checkmark", color: .neonBlue) {
                        dismiss()
                    }
                    .padding(.horizontal, AuraTheme.Spacing.lg)

                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
            }
            .auraBackground()
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "ruler.fill")
                .font(.system(size: 32))
                .cyberpunkText(color: .neonBlue)

            Text("SCAN RESULTS")
                .font(AuraTheme.Fonts.title())
                .cyberpunkText(color: .neonBlue)

            Text("Limb Ratio Analysis")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
    }

    // MARK: - Morphotype Badge

    private var morphotypeBadge: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Text("MORPHOTYPE")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(morphotype.rawValue.uppercased())
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .cyberOrange)

            Text(morphotype.description)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)
                .multilineTextAlignment(.center)
        }
        .darkCard()
        .neonGlow(color: .cyberOrange, radius: AuraTheme.Shadows.subtleGlowRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Morphotype: \(morphotype.rawValue). \(morphotype.description)")
    }

    // MARK: - Ratio Cards

    private var ratioCardsSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ratioCard(
                label: "Femur : Torso",
                value: measurements.femurToTorsoRatio,
                average: PopulationAverages.femurToTorso,
                interpretation: femurInterpretation
            )
            ratioCard(
                label: "Tibia : Femur",
                value: measurements.tibiaToFemurRatio,
                average: PopulationAverages.tibiaToFemur,
                interpretation: tibiaInterpretation
            )
            ratioCard(
                label: "Humerus : Torso",
                value: measurements.humerusToTorsoRatio,
                average: PopulationAverages.humerusToTorso,
                interpretation: humerusInterpretation
            )
            ratioCard(
                label: "Arm Span : Height",
                value: measurements.armSpanToHeightRatio,
                average: PopulationAverages.armSpanToHeight,
                interpretation: armSpanInterpretation
            )
            ratioCard(
                label: "Shoulder : Hip",
                value: measurements.shoulderToHipRatio,
                average: PopulationAverages.shoulderToHip,
                interpretation: shoulderInterpretation
            )
        }
    }

    private func ratioCard(
        label: String,
        value: Double,
        average: Double,
        interpretation: String
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                Text(label)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)

                Text(interpretation)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)

                // Deviation indicator
                deviationBar(value: value, average: average)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AuraTheme.Spacing.xxs) {
                Text(String(format: "%.2f", value))
                    .font(AuraTheme.Fonts.statValue(28))
                    .cyberpunkText(color: .neonBlue)

                Text("avg \(String(format: "%.2f", average))")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
        }
        .darkCard()
        .neonGlow(color: .neonBlue, radius: AuraTheme.Shadows.subtleGlowRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(String(format: "%.2f", value)), average \(String(format: "%.2f", average)). \(interpretation)")
    }

    private func deviationBar(value: Double, average: Double) -> some View {
        let deviation = (value - average) / average
        let color: Color = abs(deviation) < 0.05 ? .neonGreen :
                           abs(deviation) < 0.10 ? .cyberOrange : .neonRed

        return GeometryReader { geo in
            ZStack(alignment: .center) {
                // Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.auraSurfaceElevated)
                    .frame(height: 4)

                // Center marker
                Rectangle()
                    .fill(Color.auraTextDisabled)
                    .frame(width: 1, height: 8)

                // Deviation indicator
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .offset(x: CGFloat(deviation) * geo.size.width * 2)
                    .shadow(color: color.opacity(0.6), radius: 4)
            }
        }
        .frame(height: 10)
    }

    // MARK: - Risk Profile Section

    private var riskProfileSection: some View {
        let groups = BiomechanicsEngine.groupByRisk(exercises: exercises, riskMap: riskMap)

        return VStack(spacing: AuraTheme.Spacing.md) {
            Text("EXERCISE RISK PROFILE")
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.auraTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Risk summary badges
            HStack(spacing: AuraTheme.Spacing.md) {
                riskBadge(count: groups.optimal.count, risk: .optimal)
                riskBadge(count: groups.caution.count, risk: .caution)
                riskBadge(count: groups.highRisk.count, risk: .highRisk)
            }

            // Optimal exercises
            if !groups.optimal.isEmpty {
                riskGroupCard(
                    title: "OPTIMAL",
                    exercises: groups.optimal,
                    risk: .optimal
                )
            }

            // Caution exercises
            if !groups.caution.isEmpty {
                riskGroupCard(
                    title: "CAUTION",
                    exercises: groups.caution,
                    risk: .caution
                )
            }

            // High Risk exercises
            if !groups.highRisk.isEmpty {
                riskGroupCard(
                    title: "HIGH RISK",
                    exercises: groups.highRisk,
                    risk: .highRisk
                )
            }
        }
    }

    private func riskBadge(count: Int, risk: ExerciseRisk) -> some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text("\(count)")
                .font(AuraTheme.Fonts.statValue(24))
                .foregroundColor(Color(hex: risk.colorHex))

            Text(risk.displayName)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AuraTheme.Spacing.sm)
        .background(Color.auraSurfaceElevated)
        .cornerRadius(AuraTheme.Radius.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(risk.displayName) exercises")
    }

    private func riskGroupCard(
        title: String,
        exercises: [Exercise],
        risk: ExerciseRisk
    ) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color(hex: risk.colorHex))
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(Color(hex: risk.colorHex))

                Spacer()

                Text("\(exercises.count)")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }

            ForEach(exercises, id: \.id) { exercise in
                HStack {
                    Text(exercise.name)
                        .font(AuraTheme.Fonts.body())
                        .foregroundColor(.auraTextPrimary)

                    Spacer()

                    if let notes = exercise.biomechanicalNotes, !notes.isEmpty {
                        Text(notes.prefix(40) + (notes.count > 40 ? "..." : ""))
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextDisabled)
                            .lineLimit(1)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(exercise.name)\(exercise.biomechanicalNotes != nil ? ", \(exercise.biomechanicalNotes!)" : "")")
            }
        }
        .darkCard()
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("BIOMECHANICAL PROFILE")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(summary)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)
                .multilineTextAlignment(.center)
        }
        .darkCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Biomechanical profile: \(summary)")
    }

    // MARK: - Interpretations

    private var femurInterpretation: String {
        let r = measurements.femurToTorsoRatio
        if r > 0.92 { return "Long femurs — increased squat depth challenge" }
        if r < 0.78 { return "Short femurs — strong squat leverage" }
        return "Balanced femur-to-torso ratio"
    }

    private var tibiaInterpretation: String {
        let r = measurements.tibiaToFemurRatio
        if r > 0.88 { return "Long tibias — more knee travel, wider stance may help" }
        if r < 0.72 { return "Short tibias — compact lower leg, stable squat base" }
        return "Neutral knee travel"
    }

    private var humerusInterpretation: String {
        let r = measurements.humerusToTorsoRatio
        if r > 0.82 { return "Long levers — wider ROM on pressing, strong pulls" }
        if r < 0.68 { return "Short levers — mechanical pressing advantage" }
        return "Balanced upper limb proportion"
    }

    private var armSpanInterpretation: String {
        let r = measurements.armSpanToHeightRatio
        if r > 1.03 { return "Positive ape index — deadlift advantage" }
        if r < 0.97 { return "Negative ape index — shorter bar path on press" }
        return "Neutral reach index"
    }

    private var shoulderInterpretation: String {
        let r = measurements.shoulderToHipRatio
        if r > 1.40 { return "Wide clavicle structure — V-taper foundation" }
        if r < 1.20 { return "Narrow structure — focus on lateral delt development" }
        return "Balanced shoulder-to-hip ratio"
    }
}

// MARK: - Preview

#Preview {
    let measurements = SegmentMeasurements(
        torsoLength: 48.0,
        femurLengthL: 42.0, femurLengthR: 41.5,
        tibiaLengthL: 38.0, tibiaLengthR: 37.5,
        humerusLengthL: 33.0, humerusLengthR: 32.5,
        forearmLengthL: 26.0, forearmLengthR: 25.5,
        shoulderWidth: 42.0,
        hipWidth: 30.0,
        armSpan: 178.0,
        heightCm: 180.0
    )

    ScanResultsView(
        measurements: measurements,
        morphotype: .proportional,
        riskMap: [:],
        exercises: [],
        summary: "Your proportions are well-balanced across major movement patterns."
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
