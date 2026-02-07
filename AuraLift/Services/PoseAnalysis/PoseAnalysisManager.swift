import Foundation
import CoreGraphics
import Vision
import Combine

/// Processes camera frames through Vision's body pose detection pipeline.
/// Extracts 2D joint positions and publishes PoseFrame results.
final class PoseAnalysisManager: ObservableObject, ServiceProtocol {

    // MARK: - Published State

    @Published var currentPoseFrame: PoseFrame?
    @Published var isProcessing = false
    @Published var detectedPersonCount = 0

    // MARK: - ServiceProtocol

    var isAvailable: Bool { true }

    func initialize() async throws {
        // Vision requests are created on demand; no async setup needed
    }

    // MARK: - Internal

    private let poseRequest = VNDetectHumanBodyPoseRequest()
    private let minimumConfidence: Float = 0.3

    // MARK: - Frame Analysis

    /// Analyzes a single pixel buffer for human body pose and returns a PoseFrame.
    func analyzeFrame(_ pixelBuffer: CVPixelBuffer, timestamp: TimeInterval) -> PoseFrame? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

        do {
            try handler.perform([poseRequest])
        } catch {
            return nil
        }

        guard let observations = poseRequest.results, !observations.isEmpty else {
            publishFrame(nil, personCount: 0)
            return nil
        }

        let personCount = observations.count
        // Use the first (highest confidence) observation
        guard let observation = observations.first else {
            publishFrame(nil, personCount: 0)
            return nil
        }

        let frame = convertToPoseFrame(observation: observation, timestamp: timestamp)
        publishFrame(frame, personCount: personCount)
        return frame
    }

    // MARK: - Conversion

    private func convertToPoseFrame(
        observation: VNHumanBodyPoseObservation,
        timestamp: TimeInterval
    ) -> PoseFrame {
        var keypoints: [JointName: PoseKeypoint] = [:]

        for joint in JointName.allCases {
            guard let point = try? observation.recognizedPoint(joint.vnJointName),
                  point.confidence >= minimumConfidence else {
                continue
            }
            keypoints[joint] = PoseKeypoint.from(vnPoint: point, joint: joint)
        }

        return PoseFrame(keypoints: keypoints, timestamp: timestamp)
    }

    // MARK: - Publishing

    private func publishFrame(_ frame: PoseFrame?, personCount: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.currentPoseFrame = frame
            self?.detectedPersonCount = personCount
        }
    }
}
