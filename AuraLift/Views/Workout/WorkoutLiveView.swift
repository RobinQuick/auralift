import SwiftUI
import AVFoundation
import CoreData

// MARK: - WorkoutLiveView

/// Live workout view with camera preview, pose skeleton overlay, real-time
/// form scoring HUD, and exercise/set management via WorkoutViewModel.
struct WorkoutLiveView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @StateObject private var viewModel: WorkoutViewModel

    @State private var showPermissionAlert = false
    @State private var weightText = ""

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(context: context))
    }

    var body: some View {
        ZStack {
            // Layer 1: Camera preview
            if viewModel.cameraManager.permissionGranted {
                CameraPreviewView(session: viewModel.cameraManager.captureSession)
                    .ignoresSafeArea()
            } else {
                permissionDeniedView
            }

            // Layer 2: Pose overlay
            if viewModel.isSessionActive {
                PoseOverlayView(poseFrame: viewModel.poseAnalysisManager.currentPoseFrame)
                    .ignoresSafeArea()
            }

            // Layer 2.5: Ghost skeleton overlay
            if viewModel.isSessionActive && viewModel.isGhostModeEnabled {
                AROverlayView(
                    ghostPoseFrame: viewModel.ghostPoseFrame,
                    config: viewModel.ghostModeManager.ghostConfig
                )
                .ignoresSafeArea()
            }

            // Layer 2.6: LP floating particles
            if viewModel.isSessionActive {
                LPParticleView(particles: viewModel.lpParticles)
                    .ignoresSafeArea()
            }

            // Layer 3: HUD
            if viewModel.isSessionActive && viewModel.cameraManager.permissionGranted {
                hudOverlay
            }

            // Layer 3.5: Technique Mode banner
            if viewModel.showTechniqueModeBanner {
                techniqueModeBanner
            }

            // Layer 4: Form issue / auto-stop banners
            if viewModel.isSessionActive {
                feedbackBanners
            }

            // Layer 5: Control bar
            VStack {
                Spacer()
                controlBar
            }
        }
        .auraBackground()
        .task {
            await viewModel.initializePipeline()
            showPermissionAlert = viewModel.cameraManager.permissionDenied
        }
        .onDisappear {
            viewModel.frameProcessor.stop()
        }
        .alert("Camera Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("AuraLift needs camera access to analyze your exercise form. Please enable it in Settings.")
        }
        .sheet(isPresented: $viewModel.showExercisePicker) {
            ExercisePickerView { exercise in
                viewModel.selectExercise(exercise)
            }
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $viewModel.showSessionSummary) {
            sessionSummaryView
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .cyberpunkText(color: .cyberOrange)

            Text("CAMERA ACCESS REQUIRED")
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .cyberOrange)

            Text("AuraLift needs your camera to track\nexercise form in real time.")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .multilineTextAlignment(.center)

            NeonButton(title: "OPEN SETTINGS", icon: "gear", color: .cyberOrange) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        }
    }

    // MARK: - HUD Overlay

    private var hudOverlay: some View {
        VStack {
            // Top row: exercise header + combo counter
            HStack(alignment: .top) {
                exerciseHeader
                Spacer()
                comboCounter
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xxl)

            Spacer()

            // Middle row: velocity (left) + form score (right)
            HStack {
                ZStack {
                    velocityReadout
                    if !viewModel.canAccessVBT {
                        LockedOverlayView(showPaywall: $viewModel.showPaywall)
                    }
                }
                Spacer()
                formScoreView
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            Spacer()

            // Bottom center: rep counter
            repCounter
                .padding(.bottom, 100)
        }
    }

    // MARK: - Exercise Header (top-left)

    private var exerciseHeader: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
            if viewModel.currentExerciseName.isEmpty {
                Button {
                    viewModel.showExercisePicker = true
                } label: {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Image(systemName: "plus.circle.fill")
                        Text("SELECT EXERCISE")
                    }
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.cyberOrange)
                }
            } else {
                Text(viewModel.currentExerciseName.uppercased())
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)
                    .shadow(color: .black.opacity(0.8), radius: 4)

                Text("SET \(viewModel.currentSetNumber)")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.neonBlue)
                    .shadow(color: .black.opacity(0.8), radius: 4)
            }
        }
        .padding(AuraTheme.Spacing.sm)
        .background(Color.auraBlack.opacity(0.6))
        .cornerRadius(AuraTheme.Radius.small)
    }

    // MARK: - Combo Counter (top-right)

    private var comboCounter: some View {
        Group {
            if viewModel.comboCount > 0 {
                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Text("COMBO")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.neonGold)

                    Text("x\(viewModel.comboCount)")
                        .font(AuraTheme.Fonts.statValue(24))
                        .cyberpunkText(color: .neonGold)
                        .pulse()
                }
                .padding(AuraTheme.Spacing.sm)
                .background(Color.auraBlack.opacity(0.6))
                .cornerRadius(AuraTheme.Radius.small)
            }
        }
    }

    // MARK: - Velocity Readout (left)

    private var velocityReadout: some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text("VELOCITY")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(String(format: "%.2f", liveVelocity))
                .font(AuraTheme.Fonts.statValue(28))
                .foregroundColor(velocityColor)

            Text("m/s")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(velocityColor)

            // Velocity loss indicator
            if viewModel.velocityLossPercent > 0.05 {
                Text(String(format: "-%.0f%%", viewModel.velocityLossPercent * 100))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(viewModel.velocityLossPercent >= 0.20 ? .neonRed : .cyberOrange)
            }

            // RIR estimate
            if let rir = viewModel.estimatedRIR, rir <= 3 {
                Text("\(rir) RIR")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(rir <= 1 ? .neonRed : .cyberOrange)
            }
        }
        .padding(AuraTheme.Spacing.sm)
        .background(Color.auraBlack.opacity(0.6))
        .cornerRadius(AuraTheme.Radius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                .stroke(velocityColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var liveVelocity: Double {
        // Show live concentric velocity during ascending, otherwise show last set average
        if viewModel.currentPhase == .ascending && viewModel.currentConcentricVelocity > 0 {
            return viewModel.currentConcentricVelocity
        }
        return viewModel.completedSets.last?.averageVelocity ?? viewModel.currentVelocity
    }

    private var velocityColor: Color {
        let v = liveVelocity
        if v >= 0.65 { return .neonGreen }
        if v >= 0.50 { return .neonBlue }
        if v > 0 { return .cyberOrange }
        return .neonBlue
    }

    // MARK: - Form Score (right)

    private var formScoreView: some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text("FORM")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text("\(Int(viewModel.currentFormScore))")
                .font(AuraTheme.Fonts.statValue(28))
                .foregroundColor(formScoreColor)

            Text("%")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(formScoreColor)
        }
        .padding(AuraTheme.Spacing.sm)
        .background(Color.auraBlack.opacity(0.6))
        .cornerRadius(AuraTheme.Radius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                .stroke(formScoreColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var formScoreColor: Color {
        if viewModel.currentFormScore >= 90 { return .neonGreen }
        if viewModel.currentFormScore >= 70 { return .cyberOrange }
        return .neonRed
    }

    // MARK: - Rep Counter (bottom center)

    private var repCounter: some View {
        VStack(spacing: AuraTheme.Spacing.xxs) {
            Text("REPS")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text("\(viewModel.repCount)")
                .font(AuraTheme.Fonts.statValue(48))
                .cyberpunkText(color: .neonBlue)
        }
        .padding(AuraTheme.Spacing.md)
        .background(Color.auraBlack.opacity(0.6))
        .cornerRadius(AuraTheme.Radius.medium)
    }

    // MARK: - Feedback Banners

    private var feedbackBanners: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Spacer()
                .frame(height: 160)

            // Auto-stop alert (highest priority)
            if viewModel.shouldAutoStop {
                bannerView(
                    icon: "bolt.trianglebadge.exclamationmark.fill",
                    message: "Velocity drop >20% — consider ending set",
                    color: .neonRed
                )
            }

            // Form issue banner
            if let issue = viewModel.activeFormIssues.first {
                bannerView(
                    icon: issue.severity == .major ? "exclamationmark.triangle.fill" : "info.circle.fill",
                    message: issue.message,
                    color: issueBannerColor(issue.severity)
                )
            }

            Spacer()
        }
    }

    private func bannerView(icon: String, message: String, color: Color) -> some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextPrimary)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.sm)
        .background(color.opacity(0.15))
        .cornerRadius(AuraTheme.Radius.small)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                .stroke(color.opacity(0.4), lineWidth: 0.5)
        )
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func issueBannerColor(_ severity: FormIssue.IssueSeverity) -> Color {
        switch severity {
        case .minor: return .cyberOrange
        case .moderate: return .cyberOrange
        case .major: return .neonRed
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            // Weight input row (visible when exercise selected and session active)
            if viewModel.isSessionActive && viewModel.selectedExercise != nil {
                HStack(spacing: AuraTheme.Spacing.md) {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Text("KG")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)

                        TextField("0", text: $weightText)
                            .font(AuraTheme.Fonts.mono())
                            .foregroundColor(.auraTextPrimary)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .onChange(of: weightText) { _, newValue in
                                if let weight = Double(newValue) {
                                    viewModel.setWeight(weight)
                                }
                            }
                    }
                    .padding(.horizontal, AuraTheme.Spacing.md)
                    .padding(.vertical, AuraTheme.Spacing.sm)
                    .background(Color.auraSurfaceElevated)
                    .cornerRadius(AuraTheme.Radius.small)

                    NeonOutlineButton(title: "FINISH SET", icon: "checkmark.circle") {
                        viewModel.finishSet()
                    }

                    NeonOutlineButton(title: "EXERCISE", icon: "arrow.triangle.2.circlepath") {
                        viewModel.showExercisePicker = true
                    }

                    if viewModel.activeProgramDay != nil {
                        NeonOutlineButton(title: "SWAP", icon: "arrow.triangle.swap", color: .cyberOrange) {
                            viewModel.showSwapSheet = true
                        }
                    }
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
            }

            // Main controls
            HStack(spacing: AuraTheme.Spacing.xl) {
                NeonOutlineButton(title: "FLIP", icon: "camera.rotate") {
                    viewModel.cameraManager.toggleCamera()
                }

                if viewModel.isSessionActive && viewModel.selectedExercise != nil {
                    ZStack(alignment: .topTrailing) {
                        NeonOutlineButton(
                            title: "GHOST",
                            icon: viewModel.canAccessGhostMode ? "figure.stand" : "lock.fill",
                            color: viewModel.isGhostModeEnabled ? .neonGreen :
                                   viewModel.canAccessGhostMode ? .neonBlue : .auraTextSecondary
                        ) {
                            viewModel.toggleGhostMode()
                        }

                        if !viewModel.canAccessGhostMode {
                            PremiumBadge(.small)
                                .offset(x: 4, y: -6)
                        }
                    }
                }

                if viewModel.isSessionActive {
                    NeonButton(title: "END SESSION", icon: "stop.fill", color: .neonRed) {
                        viewModel.endSession()
                    }
                } else {
                    NeonButton(title: "START", icon: "play.fill", color: .cyberOrange) {
                        viewModel.startSession()
                    }
                }
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.lg)
        .background(
            Color.auraBlack.opacity(0.8)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Session Summary

    private var sessionSummaryView: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            // Header
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 48))
                    .cyberpunkText(color: .neonGold)

                Text("SESSION COMPLETE")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: .neonBlue)
            }
            .padding(.top, AuraTheme.Spacing.xxl)

            // Promotion banner
            if let promotion = viewModel.promotionStatus, promotion.isPromoted,
               let newTier = promotion.newTier {
                VStack(spacing: AuraTheme.Spacing.sm) {
                    Image(systemName: newTier.iconName)
                        .font(.system(size: 32))
                        .foregroundColor(newTier.color)

                    Text("PROMOTED TO \(newTier.displayName.uppercased())")
                        .font(AuraTheme.Fonts.heading())
                        .cyberpunkText(color: newTier.color)
                }
                .frame(maxWidth: .infinity)
                .darkCard()
                .neonGlow(color: newTier.color, radius: AuraTheme.Shadows.glowRadius)
                .padding(.horizontal, AuraTheme.Spacing.lg)
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AuraTheme.Spacing.md) {
                summaryStatCard(title: "TOTAL VOLUME", value: String(format: "%.0f kg", viewModel.sessionVolume), color: .neonBlue)
                summaryStatCard(title: "SETS", value: "\(viewModel.completedSets.count)", color: .neonBlue)
                summaryStatCard(title: "AVG FORM", value: "\(Int(viewModel.averageFormScore))%", color: formScoreColor)
                if viewModel.canAccessVBT {
                    summaryStatCard(title: "PEAK VELOCITY", value: String(format: "%.2f m/s", viewModel.sessionPeakVelocity), color: .neonBlue)
                } else {
                    ZStack {
                        summaryStatCard(title: "PEAK VELOCITY", value: "---", color: .auraTextDisabled)
                        LockedOverlayView(showPaywall: $viewModel.showPaywall)
                    }
                }
                summaryStatCard(title: "XP EARNED", value: "+\(viewModel.sessionXP)", color: .neonGold)
                summaryStatCard(title: "LP EARNED", value: "+\(viewModel.workoutLP)", color: .neonGold)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            // Set breakdown
            if !viewModel.completedSets.isEmpty {
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
                    Text("SET BREAKDOWN")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextSecondary)
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    ForEach(viewModel.completedSets) { set in
                        HStack {
                            Text("#\(set.setNumber)")
                                .font(AuraTheme.Fonts.mono())
                                .foregroundColor(.neonBlue)
                                .frame(width: 30, alignment: .leading)

                            Text("\(set.reps)x\(String(format: "%.0f", set.weightKg))")
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.auraTextPrimary)

                            Spacer()

                            // Velocity badge
                            Text(String(format: "%.2f", set.averageVelocity))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.auraBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(set.averageVelocity >= 0.65 ? Color.neonGreen :
                                                   set.averageVelocity >= 0.50 ? Color.cyberOrange : Color.neonRed)
                                )

                            Text("\(Int(set.averageFormScore))%")
                                .font(AuraTheme.Fonts.mono())
                                .foregroundColor(set.averageFormScore >= 90 ? .neonGreen :
                                                 set.averageFormScore >= 70 ? .cyberOrange : .neonRed)
                                .frame(width: 36)

                            Text("RPE \(String(format: "%.0f", set.rpe))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(set.rpe >= 9 ? .neonRed : set.rpe >= 8 ? .cyberOrange : .auraTextSecondary)
                        }
                        .darkCard()
                        .padding(.horizontal, AuraTheme.Spacing.lg)
                    }
                }
            }

            Spacer()

            NeonButton(title: "DONE", icon: "checkmark", color: .neonBlue) {
                viewModel.dismissSummary()
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.bottom, AuraTheme.Spacing.xxl)
        }
        .auraBackground()
    }

    // MARK: - Technique / Volume Mode Banner

    private var techniqueModeBanner: some View {
        let isVolume = viewModel.sessionMode == .volume
        let bannerColor: Color = isVolume ? .neonPurple : .cyberOrange
        let bannerIcon = isVolume ? "arrow.down.heart.fill" : "gauge.with.dots.needle.0percent"
        let bannerText = isVolume
            ? "VOLUME MODE — -20% load, +2 reps"
            : "TECHNIQUE MODE — Lighter load, slower tempo"

        return VStack {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: bannerIcon)
                    .font(.system(size: 16))
                    .foregroundColor(bannerColor)

                Text(bannerText)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(bannerColor)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.vertical, AuraTheme.Spacing.sm)
            .background(bannerColor.opacity(0.15))
            .cornerRadius(AuraTheme.Radius.small)
            .padding(.top, 60)

            Spacer()
        }
    }

    private func summaryStatCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            Text(title)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(value)
                .font(AuraTheme.Fonts.statValue(28))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
    }
}

// MARK: - Preview

#Preview {
    WorkoutLiveView(context: PersistenceController.preview.container.viewContext)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
