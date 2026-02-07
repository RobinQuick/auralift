import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - ScanState

/// Tracks the morpho scan flow progression.
enum ScanState: Equatable {
    case idle
    case positioning
    case capturing(progress: Double)
    case processing
    case complete
    case error(String)

    static func == (lhs: ScanState, rhs: ScanState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.positioning, .positioning),
             (.processing, .processing),
             (.complete, .complete):
            return true
        case let (.capturing(a), .capturing(b)):
            return a == b
        case let (.error(a), .error(b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - MorphoScanViewModel

@MainActor
class MorphoScanViewModel: ObservableObject {

    // MARK: - Published State

    @Published var scanState: ScanState = .idle
    @Published var tposeConfidence: Double = 0
    @Published var currentPoseFrame: PoseFrame?
    @Published var hasPreviousScan: Bool = false
    @Published var previousScanDate: Date?
    @Published var capturedMeasurements: SegmentMeasurements?
    @Published var exerciseRiskMap: [UUID: ExerciseRisk] = [:]
    @Published var biomechanicalSummary: String = ""
    @Published var morphotype: Morphotype = .proportional
    @Published var exercises: [Exercise] = []

    // MARK: - Dependencies

    let cameraManager: CameraManager
    let poseAnalysisManager: PoseAnalysisManager
    let frameProcessor: FrameProcessor
    private let scannerService = MorphoScannerService()
    private let biomechanicsEngine = BiomechanicsEngine()
    private let context: NSManagedObjectContext

    // MARK: - Frame Collection

    private let targetFrameCount = 15
    private var capturedFrames: [PoseFrame] = []
    private var poseSubscription: AnyCancellable?

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        let camera = CameraManager()
        let pose = PoseAnalysisManager()
        let processor = FrameProcessor(cameraManager: camera, poseAnalysisManager: pose)
        self.cameraManager = camera
        self.poseAnalysisManager = pose
        self.frameProcessor = processor
    }

    // MARK: - Load Previous Scan

    func loadPreviousScan() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MorphoScan")
        request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        request.fetchLimit = 1

        guard let scan = try? context.fetch(request).first else {
            hasPreviousScan = false
            return
        }

        previousScanDate = scan.value(forKey: "scanDate") as? Date
        hasPreviousScan = true
    }

    func loadExercises() {
        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        exercises = (try? context.fetch(request)) ?? []
    }

    // MARK: - Scan Flow

    /// Step 1: Start camera, subscribe to pose frames for T-pose confidence.
    func startPositioning() {
        scanState = .positioning
        capturedFrames = []

        Task {
            do {
                try await frameProcessor.initialize()
                frameProcessor.start()
            } catch {
                scanState = .error("Camera initialization failed: \(error.localizedDescription)")
                return
            }
        }

        // Subscribe to pose frames for real-time T-pose confidence
        poseSubscription = poseAnalysisManager.$currentPoseFrame
            .receive(on: DispatchQueue.main)
            .sink { [weak self] frame in
                guard let self else { return }
                self.currentPoseFrame = frame

                if let frame {
                    self.tposeConfidence = self.scannerService.tposeConfidence(frame)
                } else {
                    self.tposeConfidence = 0
                }

                // If capturing, collect valid T-pose frames
                if case .capturing = self.scanState, let frame, self.scannerService.isTpose(frame) {
                    self.collectFrame(frame)
                }
            }
    }

    /// Step 2: Begin frame capture (requires T-pose confidence >= 0.7).
    func beginCapture() {
        guard tposeConfidence >= 0.7 else { return }
        capturedFrames = []
        scanState = .capturing(progress: 0)
    }

    /// Collects a valid T-pose frame during capture phase.
    private func collectFrame(_ frame: PoseFrame) {
        capturedFrames.append(frame)
        let progress = Double(capturedFrames.count) / Double(targetFrameCount)
        scanState = .capturing(progress: min(progress, 1.0))

        if capturedFrames.count >= targetFrameCount {
            processCapture()
        }
    }

    /// Step 3: Process captured frames into measurements.
    private func processCapture() {
        poseSubscription?.cancel()
        frameProcessor.stop()
        scanState = .processing

        // Get user height from profile
        let heightCm = fetchUserHeight()
        guard heightCm > 0 else {
            scanState = .error("Height not set. Please update your profile first.")
            return
        }

        let frames = capturedFrames
        loadExercises()

        // Compute measurements
        guard let measurements = scannerService.computeMeasurements(
            frames: frames,
            heightCm: heightCm
        ) else {
            scanState = .error("Could not compute measurements. Please try again with full body visible.")
            return
        }

        capturedMeasurements = measurements
        morphotype = scannerService.classifyMorphotype(measurements)
        biomechanicalSummary = biomechanicsEngine.generateSummary(measurements, morphotype: morphotype)
        exerciseRiskMap = biomechanicsEngine.assessAllExercises(
            measurements: measurements,
            exercises: exercises
        )

        // Save to CoreData
        saveScan(measurements, riskMap: exerciseRiskMap, rawData: scannerService.serializePoseData(frames))
        scanState = .complete
    }

    /// Cancel scan at any point.
    func cancelScan() {
        poseSubscription?.cancel()
        frameProcessor.stop()
        capturedFrames = []
        tposeConfidence = 0
        currentPoseFrame = nil
        scanState = .idle
    }

    /// Retry after error.
    func retry() {
        scanState = .idle
    }

    // MARK: - CoreData Save

    private func saveScan(
        _ measurements: SegmentMeasurements,
        riskMap: [UUID: ExerciseRisk],
        rawData: Data?
    ) {
        let scan = MorphoScan(context: context)
        scan.scanDate = Date()
        scan.torsoLength = measurements.torsoLength
        scan.femurLength = measurements.femurLength
        scan.tibiaLength = measurements.tibiaLength
        scan.humerusLength = measurements.humerusLength
        scan.forearmLength = measurements.forearmLength
        scan.shoulderWidth = measurements.shoulderWidth
        scan.hipWidth = measurements.hipWidth
        scan.armSpan = measurements.armSpan
        scan.femurToTorsoRatio = measurements.femurToTorsoRatio
        scan.tibiaToFemurRatio = measurements.tibiaToFemurRatio
        scan.humerusToTorsoRatio = measurements.humerusToTorsoRatio
        scan.rawPoseData = rawData

        // Link to user profile
        let profileRequest = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        if let profile = try? context.fetch(profileRequest).first {
            scan.userProfile = profile
        }

        // Update exercise risk levels
        for exercise in exercises {
            if let risk = riskMap[exercise.id] {
                exercise.riskLevel = risk.rawValue
            }
        }

        do {
            try context.save()
            hasPreviousScan = true
            previousScanDate = scan.scanDate
        } catch {
            scanState = .error("Failed to save scan: \(error.localizedDescription)")
        }
    }

    // MARK: - Helpers

    private func fetchUserHeight() -> Double {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let profile = try? context.fetch(request).first else { return 0 }
        return (profile.value(forKey: "heightCm") as? Double) ?? 0
    }
}
