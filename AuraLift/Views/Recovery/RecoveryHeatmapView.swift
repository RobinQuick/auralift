import SwiftUI
import CoreData

/// Main Recovery Dashboard combining readiness score, muscle heatmap, biometrics,
/// and training adjustment recommendations with cyberpunk styling.
struct RecoveryHeatmapView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: RecoveryViewModel

    @State private var selectedSegment = 0

    init() {
        // Placeholder — actual context injected via .environment
        _viewModel = StateObject(wrappedValue: RecoveryViewModel(
            context: PersistenceController.shared.container.viewContext
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                // MARK: - Header
                headerSection

                // MARK: - Deload Banner
                if let deload = viewModel.deloadRecommendation, deload.shouldDeload {
                    deloadBanner(deload)
                }

                // MARK: - Readiness Ring
                readinessRing

                // MARK: - Training Adjustment
                if let adjustment = viewModel.trainingAdjustment {
                    adjustmentCard(adjustment)
                }

                // MARK: - Segment Picker
                Picker("View", selection: $selectedSegment) {
                    Text("Heatmap").tag(0)
                    Text("Biometrics").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AuraTheme.Spacing.lg)
                .accessibilityLabel("Recovery view selector")

                // MARK: - Content
                if selectedSegment == 0 {
                    heatmapSection
                } else {
                    BioMetricsView(viewModel: viewModel)
                }

                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
        }
        .auraBackground()
        .task {
            await viewModel.refreshData()
        }
        .refreshable {
            await viewModel.refreshData()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "heart.fill")
                .font(.system(size: 36))
                .cyberpunkText(color: .neonGreen)

            Text("RECOVERY")
                .font(AuraTheme.Fonts.title())
                .cyberpunkText(color: .neonGreen)

            Text(viewModel.readinessLevel.displayName)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(viewModel.readinessColor)
        }
        .padding(.top, AuraTheme.Spacing.xl)
    }

    // MARK: - Deload Banner

    private func deloadBanner(_ deload: DeloadRecommendation) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.neonRed)
                Text("AUTO-DELOAD RECOMMENDED")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.neonRed)
            }

            if let reason = deload.reason {
                Text(reason.displayDescription)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Text("Reduce load by \(Int(deload.suggestedLoadReduction * 100))% for \(deload.durationDays) days")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.cyberOrange)
        }
        .frame(maxWidth: .infinity)
        .padding(AuraTheme.Spacing.md)
        .background(Color.neonRed.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(Color.neonRed.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(AuraTheme.Radius.medium)
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .neonGlow(color: .neonRed, radius: AuraTheme.Shadows.subtleGlowRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Auto-deload recommended. Reduce load by \(Int(deload.suggestedLoadReduction * 100)) percent for \(deload.durationDays) days")
    }

    // MARK: - Readiness Ring

    private var readinessRing: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Color.auraSurfaceElevated, lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: min(1.0, viewModel.overallReadiness / 100.0))
                    .stroke(
                        viewModel.readinessColor,
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: viewModel.readinessColor.opacity(0.5), radius: 8)
                    .animation(.easeInOut(duration: 0.8), value: viewModel.overallReadiness)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("\(Int(viewModel.overallReadiness))")
                        .font(AuraTheme.Fonts.statValue(36))
                        .foregroundColor(viewModel.readinessColor)
                    Text("READINESS")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
            }

            // Cycle phase badge
            if let phase = viewModel.cyclePhase {
                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "circle.hexagongrid.fill")
                        .foregroundColor(.neonPurple)
                    Text(phase.displayName)
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(.neonPurple)
                    Text("(\(phase.dayRange))")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
                .darkCard()
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Cycle phase: \(phase.displayName), days \(phase.dayRange)")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Readiness score: \(Int(viewModel.overallReadiness)) out of 100")
    }

    // MARK: - Training Adjustment

    private func adjustmentCard(_ adjustment: TrainingAdjustment) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "gauge.with.needle.fill")
                    .foregroundColor(.neonBlue)
                Text("TRAINING ADJUSTMENT")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
            }

            Text(adjustment.recommendation)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AuraTheme.Spacing.lg) {
                modifierBadge(
                    label: "Volume",
                    value: adjustment.volumeModifier,
                    icon: "chart.bar.fill"
                )
                modifierBadge(
                    label: "Intensity",
                    value: adjustment.intensityModifier,
                    icon: "bolt.fill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Training adjustment: \(adjustment.recommendation)")
    }

    private func modifierBadge(label: String, value: Double, icon: String) -> some View {
        let color: Color = value >= 1.0 ? .neonGreen : (value >= 0.8 ? .cyberOrange : .neonRed)
        let percentage = Int((value - 1.0) * 100)
        let sign = percentage >= 0 ? "+" : ""

        return VStack(spacing: AuraTheme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
            Text("\(sign)\(percentage)%")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Heatmap Section

    private var heatmapSection: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            // Body silhouette placeholder
            bodyHeatmapPlaceholder

            // Legend
            legendRow

            // Muscle groups by region
            if !viewModel.muscleStatuses.isEmpty {
                muscleRegionSection(title: "UPPER BODY", region: "upper")
                muscleRegionSection(title: "LOWER BODY", region: "lower")
                muscleRegionSection(title: "CORE", region: "core")
            } else {
                Text("No training data yet")
                    .font(AuraTheme.Fonts.body())
                    .foregroundColor(.auraTextDisabled)
                    .padding(.vertical, AuraTheme.Spacing.xxl)
            }
        }
    }

    private var bodyHeatmapPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AuraTheme.Radius.large)
                .fill(Color.auraSurfaceElevated)
                .frame(width: 200, height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.large)
                        .stroke(Color.neonGreen.opacity(0.3), lineWidth: 1)
                )

            VStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 100))
                    .foregroundStyle(
                        LinearGradient(
                            colors: heatmapGradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.7)

                Text("MUSCLE MAP")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
        }
        .shadow(color: .neonGreen.opacity(0.15), radius: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Muscle map overview")
    }

    private var heatmapGradientColors: [Color] {
        let avg = viewModel.muscleRecoveryAverage
        if avg >= 80 { return [.neonGreen, .neonGreen.opacity(0.6)] }
        if avg >= 55 { return [.neonGreen, .cyberOrange] }
        return [.cyberOrange, .neonRed]
    }

    private var legendRow: some View {
        HStack(spacing: AuraTheme.Spacing.lg) {
            legendItem(color: .neonGreen, label: "Recovered")
            legendItem(color: .cyberOrange, label: "Moderate")
            legendItem(color: .neonRed, label: "Fatigued")
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: AuraTheme.Spacing.xs) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.5), radius: 3)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
    }

    // MARK: - Muscle Region Section

    private func muscleRegionSection(title: String, region: String) -> some View {
        let muscles = viewModel.musclesByRegion(region)
        guard !muscles.isEmpty else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                Text(title)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextSecondary)
                    .padding(.horizontal, AuraTheme.Spacing.lg)

                ForEach(muscles, id: \.muscleName) { status in
                    muscleZoneRow(status)
                }
            }
        )
    }

    private func muscleZoneRow(_ status: MuscleRecoveryStatus) -> some View {
        let color = recoveryColor(status.recoveryPercent / 100.0)
        let isSelected = viewModel.selectedMuscle == status.muscleName

        return VStack(spacing: 0) {
            HStack(spacing: AuraTheme.Spacing.md) {
                // Recovery zone indicator
                Circle()
                    .fill(color)
                    .frame(width: 10, height: 10)
                    .shadow(color: color.opacity(0.6), radius: 3)

                Text(status.muscleName)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Recovery bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                            .fill(Color.auraSurface)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                            .fill(color)
                            .frame(width: geometry.size.width * min(1.0, status.recoveryPercent / 100.0), height: 6)
                            .shadow(color: color.opacity(0.5), radius: 3)
                    }
                }
                .frame(width: 80, height: 6)

                Text("\(Int(status.recoveryPercent))%")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(color)
                    .frame(width: 44, alignment: .trailing)
            }
            .darkCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(status.muscleName), recovery \(Int(status.recoveryPercent)) percent")
            .accessibilityHint("Double tap to expand")
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectedMuscle = isSelected ? nil : status.muscleName
                }
            }

            // Expanded detail
            if isSelected {
                HStack(spacing: AuraTheme.Spacing.lg) {
                    detailItem(
                        label: "Volume",
                        value: "\(status.weeklyVolumeSets) sets"
                    )
                    detailItem(
                        label: "Time",
                        value: status.hoursSinceTraining < 999
                            ? "\(Int(status.hoursSinceTraining))h ago"
                            : "N/A"
                    )
                    detailItem(
                        label: "Full Recovery",
                        value: status.estimatedFullRecoveryHours > 0
                            ? "\(Int(status.estimatedFullRecoveryHours))h"
                            : "N/A"
                    )
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
                .padding(.bottom, AuraTheme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func detailItem(label: String, value: String) -> some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
            Text(value)
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func recoveryColor(_ value: Double) -> Color {
        if value >= 0.80 { return .neonGreen }
        if value >= 0.55 { return .cyberOrange }
        return .neonRed
    }
}

// MARK: - Preview

#Preview {
    RecoveryHeatmapView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
