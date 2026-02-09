import Foundation
import AVFoundation
import CoreMedia
import Combine

/// Bridges CameraManager output to PoseAnalysisManager input with throttling and backpressure.
final class FrameProcessor: ObservableObject, ServiceProtocol {

    // MARK: - Dependencies

    let cameraManager: CameraManager
    let poseAnalysisManager: PoseAnalysisManager

    // MARK: - Published State

    @Published var isActive = false

    // MARK: - ServiceProtocol

    var isAvailable: Bool { cameraManager.isAvailable }

    // MARK: - Throttling

    private var targetFPS: Int = 30
    private var lastProcessedTime: TimeInterval = 0
    private var isCurrentlyProcessing = false
    private let processingQueue = DispatchQueue(label: "com.aurea.frameProcessor", qos: .userInitiated)

    private var minFrameInterval: TimeInterval {
        1.0 / Double(targetFPS)
    }

    // MARK: - Init

    init(cameraManager: CameraManager, poseAnalysisManager: PoseAnalysisManager) {
        self.cameraManager = cameraManager
        self.poseAnalysisManager = poseAnalysisManager
    }

    deinit {
        cameraManager.onFrameCaptured = nil
    }

    // MARK: - Initialize

    func initialize() async throws {
        try await cameraManager.initialize()
        try await poseAnalysisManager.initialize()

        cameraManager.onFrameCaptured = { [weak self] sampleBuffer in
            self?.processFrame(sampleBuffer)
        }
    }

    // MARK: - Frame Processing

    private func processFrame(_ sampleBuffer: CMSampleBuffer) {
        let currentTime = CACurrentMediaTime()

        // Throttle: skip if too soon since last processed frame
        guard (currentTime - lastProcessedTime) >= minFrameInterval else { return }

        // Backpressure: skip if previous frame is still being analyzed
        guard !isCurrentlyProcessing else { return }

        // Extract pixel buffer from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds

        isCurrentlyProcessing = true
        lastProcessedTime = currentTime

        DispatchQueue.main.async { [weak self] in
            self?.poseAnalysisManager.isProcessing = true
        }

        processingQueue.async { [weak self] in
            guard let self else { return }

            _ = self.poseAnalysisManager.analyzeFrame(pixelBuffer, timestamp: timestamp)

            self.isCurrentlyProcessing = false

            DispatchQueue.main.async {
                self.poseAnalysisManager.isProcessing = false
            }
        }
    }

    // MARK: - Session Control

    func start() {
        cameraManager.startSession()
        DispatchQueue.main.async { [weak self] in
            self?.isActive = true
        }
    }

    func stop() {
        cameraManager.stopSession()
        DispatchQueue.main.async { [weak self] in
            self?.isActive = false
        }
    }

    // MARK: - Configuration

    func setProcessingRate(fps: Int) {
        targetFPS = max(1, min(60, fps))
    }
}
