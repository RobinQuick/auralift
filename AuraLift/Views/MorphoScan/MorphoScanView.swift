import SwiftUI
import CoreData

/// Camera-driven morpho scan UI with T-pose guide, confidence ring,
/// frame capture progress, and navigation to results.
struct MorphoScanView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: MorphoScanViewModel

    @State private var showResults = false
    @State private var showPrivacyConsent = false

    init(context: NSManagedObjectContext? = nil) {
        // Context will be injected via environment; use a temporary for init
        let ctx = context ?? PersistenceController.preview.container.viewContext
        _viewModel = StateObject(wrappedValue: MorphoScanViewModel(context: ctx))
    }

    var body: some View {
        ZStack {
            switch viewModel.scanState {
            case .idle:
                idleView
            case .positioning:
                cameraView
            case .capturing(let progress):
                cameraView
                    .overlay(alignment: .bottom) {
                        captureProgressBar(progress: progress)
                    }
            case .processing:
                processingView
            case .complete:
                Color.clear
                    .onAppear { showResults = true }
            case .error(let message):
                errorView(message: message)
            }
        }
        .auraBackground()
        .onAppear {
            viewModel.loadPreviousScan()
        }
        .onDisappear {
            if case .idle = viewModel.scanState { return }
            if case .complete = viewModel.scanState { return }
            if case .error = viewModel.scanState { return }
            viewModel.cancelScan()
        }
        .fullScreenCover(isPresented: $showResults) {
            if let measurements = viewModel.capturedMeasurements {
                ScanResultsView(
                    measurements: measurements,
                    morphotype: viewModel.morphotype,
                    riskMap: viewModel.exerciseRiskMap,
                    exercises: viewModel.exercises,
                    summary: viewModel.biomechanicalSummary
                )
                .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showPrivacyConsent) {
            PrivacyConsentView(
                onAccepted: {
                    showPrivacyConsent = false
                    viewModel.startPositioning()
                },
                onRefused: {
                    showPrivacyConsent = false
                }
            )
        }
    }

    // MARK: - Idle View

    private var idleView: some View {
        VStack(spacing: AuraTheme.Spacing.xxl) {
            Spacer()

            // Header
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 40))
                    .cyberpunkText(color: .neonBlue)

                Text("MORPHO SCAN")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: .neonBlue)

                Text("Anthropometric Analysis")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            // Instructions card
            VStack(spacing: AuraTheme.Spacing.md) {
                instructionRow(icon: "ruler", text: "Stand 2 meters from camera")
                instructionRow(icon: "figure.arms.open", text: "Extend arms in T-pose")
                instructionRow(icon: "person.fill.viewfinder", text: "Full body must be visible")
                instructionRow(icon: "hand.raised.fill", text: "Hold still during capture")
            }
            .darkCard()
            .padding(.horizontal, AuraTheme.Spacing.lg)

            // Begin Scan button
            NeonButton(title: "BEGIN SCAN", icon: "viewfinder", color: .neonBlue) {
                if PrivacyConsentView.isConsentAccepted {
                    viewModel.startPositioning()
                } else {
                    showPrivacyConsent = true
                }
            }

            // Previous scan info
            if viewModel.hasPreviousScan, let date = viewModel.previousScanDate {
                Text("Last scan: \(date, style: .date)")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }

            Spacer()
        }
    }

    private func instructionRow(icon: String, text: String) -> some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.neonBlue)
                .frame(width: 28)

            Text(text)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)

            Spacer()
        }
    }

    // MARK: - Camera View (Positioning + Capturing)

    private var cameraView: some View {
        ZStack {
            // Camera preview
            if viewModel.cameraManager.permissionGranted {
                CameraPreviewView(session: viewModel.cameraManager.captureSession)
                    .ignoresSafeArea()
            } else if viewModel.cameraManager.permissionDenied {
                permissionDeniedView
            } else {
                Color.auraBlack
                    .ignoresSafeArea()
            }

            // Skeleton overlay
            PoseOverlayView(poseFrame: viewModel.currentPoseFrame)
                .ignoresSafeArea()

            // T-pose silhouette guide
            tposeSilhouette

            // HUD elements
            VStack {
                // Top bar: confidence ring + status
                HStack {
                    Spacer()
                    confidenceRing
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
                .padding(.top, AuraTheme.Spacing.xxl)

                Spacer()

                // Status text
                statusText

                // Control bar
                cameraControlBar
            }
        }
    }

    // MARK: - T-Pose Silhouette Guide

    private var tposeSilhouette: some View {
        Image(systemName: "figure.arms.open")
            .font(.system(size: 200))
            .foregroundColor(.neonBlue.opacity(confidenceOpacity))
            .shadow(color: .neonBlue.opacity(confidenceOpacity * 0.5), radius: 12)
            .accessibilityLabel("T-pose alignment guide")
    }

    private var confidenceOpacity: Double {
        if viewModel.tposeConfidence >= 0.7 { return 0.15 }
        return 0.25 - (viewModel.tposeConfidence * 0.1)
    }

    // MARK: - Confidence Ring

    private var confidenceRing: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.auraSurfaceElevated, lineWidth: 4)
                .frame(width: 56, height: 56)

            // Progress arc
            Circle()
                .trim(from: 0, to: viewModel.tposeConfidence)
                .stroke(
                    confidenceColor,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 56, height: 56)
                .rotationEffect(.degrees(-90))

            // Percentage text
            Text("\(Int(viewModel.tposeConfidence * 100))")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(confidenceColor)
        }
        .padding(AuraTheme.Spacing.sm)
        .background(Color.auraBlack.opacity(0.6))
        .cornerRadius(AuraTheme.Radius.medium)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("T-pose confidence: \(Int(viewModel.tposeConfidence * 100)) percent")
    }

    private var confidenceColor: Color {
        if viewModel.tposeConfidence >= 0.7 { return .neonGreen }
        if viewModel.tposeConfidence >= 0.5 { return .cyberOrange }
        return .neonRed
    }

    // MARK: - Status Text

    private var statusText: some View {
        Group {
            if case .capturing(let progress) = viewModel.scanState {
                VStack(spacing: AuraTheme.Spacing.xs) {
                    Text("CAPTURING...")
                        .font(AuraTheme.Fonts.subheading())
                        .cyberpunkText(color: .neonBlue)

                    Text("\(Int(progress * 100))%")
                        .font(AuraTheme.Fonts.statValue(28))
                        .foregroundColor(.neonBlue)
                }
                .padding(AuraTheme.Spacing.md)
                .background(Color.auraBlack.opacity(0.7))
                .cornerRadius(AuraTheme.Radius.medium)
            } else if viewModel.tposeConfidence >= 0.7 {
                Text("HOLD T-POSE — READY TO CAPTURE")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonGreen)
                    .padding(AuraTheme.Spacing.sm)
                    .background(Color.auraBlack.opacity(0.7))
                    .cornerRadius(AuraTheme.Radius.small)
            } else if viewModel.currentPoseFrame != nil {
                Text("ALIGN BODY IN T-POSE")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.cyberOrange)
                    .padding(AuraTheme.Spacing.sm)
                    .background(Color.auraBlack.opacity(0.7))
                    .cornerRadius(AuraTheme.Radius.small)
            } else {
                Text("STEP INTO FRAME")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.auraTextSecondary)
                    .padding(AuraTheme.Spacing.sm)
                    .background(Color.auraBlack.opacity(0.7))
                    .cornerRadius(AuraTheme.Radius.small)
            }
        }
        .padding(.bottom, AuraTheme.Spacing.lg)
    }

    // MARK: - Camera Control Bar

    private var cameraControlBar: some View {
        HStack(spacing: AuraTheme.Spacing.xl) {
            // Cancel
            NeonOutlineButton(title: "CANCEL", icon: "xmark") {
                viewModel.cancelScan()
            }

            // Capture button (only when not already capturing)
            if case .capturing = viewModel.scanState {
                // Progress shown via overlay bar, no button needed
            } else {
                NeonButton(
                    title: "CAPTURE",
                    icon: "camera.viewfinder",
                    color: viewModel.tposeConfidence >= 0.7 ? .neonBlue : .auraTextDisabled
                ) {
                    viewModel.beginCapture()
                }
                .disabled(viewModel.tposeConfidence < 0.7)
                .opacity(viewModel.tposeConfidence >= 0.7 ? 1.0 : 0.5)
            }

            // Camera flip
            NeonOutlineButton(title: "FLIP", icon: "camera.rotate") {
                viewModel.cameraManager.toggleCamera()
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.lg)
        .background(
            Color.auraBlack.opacity(0.8)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Capture Progress Bar

    private func captureProgressBar(progress: Double) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.auraSurfaceElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.neonBlue)
                        .frame(width: geo.size.width * progress, height: 8)
                        .shadow(color: .neonBlue.opacity(0.6), radius: 6)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, AuraTheme.Spacing.xxl)
        .padding(.bottom, 120) // Above control bar
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Capture progress: \(Int(progress * 100)) percent")
    }

    // MARK: - Processing View

    private var processingView: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .neonBlue))
                .scaleEffect(1.5)

            Text("ANALYZING PROPORTIONS...")
                .font(AuraTheme.Fonts.subheading())
                .cyberpunkText(color: .neonBlue)

            Text("Computing limb ratios and biomechanical profile")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Spacer()
        }
    }

    // MARK: - Permission Denied View

    private var permissionDeniedView: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundColor(.neonRed)

            Text("CAMERA ACCESS DENIED")
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .neonRed)

            Text("AUREA needs camera access to perform morpho scans.\nGo to Settings → AUREA → Camera to enable it.")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AuraTheme.Spacing.xxl)

            NeonButton(title: "OPEN SETTINGS", icon: "gear", color: .neonBlue) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }

            NeonOutlineButton(title: "BACK", icon: "arrow.left") {
                viewModel.cancelScan()
            }

            Spacer()
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.cyberOrange)

            Text("SCAN FAILED")
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .cyberOrange)

            Text(message)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AuraTheme.Spacing.xxl)

            NeonButton(title: "RETRY", icon: "arrow.clockwise", color: .cyberOrange) {
                viewModel.retry()
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    MorphoScanView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
