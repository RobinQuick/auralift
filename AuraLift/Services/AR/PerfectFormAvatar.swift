import Foundation
import CoreGraphics
import SwiftUI

// MARK: - IdealPoseSnapshot

/// A snapshot of the ideal joint positions for a specific rep phase.
struct IdealPoseSnapshot {
    let phase: RepPhase
    let keypoints: [JointName: CGPoint]
}

// MARK: - GhostOverlayConfig

/// Visual configuration for the ghost skeleton overlay.
struct GhostOverlayConfig {
    var opacity: Double = 0.4
    let lineColor: Color = .neonGreen
    let dotColor: Color = .neonGreen
    let lineWidth: CGFloat = 2.0
    let dotRadius: CGFloat = 3.0
}

// MARK: - PerfectFormAvatar

/// Pure computation class that generates an ideal PoseFrame per rep phase
/// from exercise form profiles and user body proportions. No 3D models —
/// outputs 2D joint positions for Canvas overlay rendering.
final class PerfectFormAvatar: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - State

    private var currentProfile: ExerciseFormProfile?
    private var segments: SegmentMeasurements?
    private var referenceFrame: PoseFrame?
    private var userHeightCm: Double = 175.0
    private(set) var overlayOpacity: Double = 0.4

    // MARK: - Configuration

    /// Configures the avatar for a specific exercise with user proportions.
    func configure(exerciseName: String, segments: SegmentMeasurements?, referenceFrame: PoseFrame?) {
        self.currentProfile = FormAnalyzer.profiles[exerciseName]
        self.segments = segments
        self.referenceFrame = referenceFrame
    }

    /// Sets the ghost overlay opacity.
    func setOpacity(_ opacity: Double) {
        overlayOpacity = max(0, min(1, opacity))
    }

    /// Stores height for calibration.
    func scaleToUser(heightCm: Double) {
        guard heightCm > 0 else { return }
        userHeightCm = heightCm
    }

    // MARK: - Ideal Pose Computation

    /// Computes the ideal PoseFrame for the current rep phase, anchored to the user's real position.
    ///
    /// Algorithm:
    /// 1. Determine target angle from phase (top/bottom/interpolated)
    /// 2. Anchor root/hip from user's real frame
    /// 3. Compute ideal tracked joint positions using target angle + segment lengths
    /// 4. Copy all other joints from the user's real frame
    func computeIdealPoseFrame(for phase: RepPhase, anchorFrame: PoseFrame) -> PoseFrame? {
        guard let profile = currentProfile else { return nil }

        let targetAngle = targetAngleForPhase(phase, profile: profile)
        guard let targetAngle else { return nil }

        let tracking = profile.trackingAngleJoints

        // Get user's real joint positions as base
        var idealKeypoints = anchorFrame.keypoints

        // Compute ideal positions for the tracked joints
        guard let vertexPos = anchorFrame[tracking.vertex]?.position,
              let fromPos = anchorFrame[tracking.from]?.position else {
            return nil
        }

        // Calculate segment lengths from user data or anchor frame
        let fromToVertexLen = segmentLength(from: tracking.from, to: tracking.vertex, anchorFrame: anchorFrame)
        let vertexToToLen = segmentLength(from: tracking.vertex, to: tracking.to, anchorFrame: anchorFrame)

        // Compute the direction from vertex to "from" joint
        let fromDir = atan2(fromPos.y - vertexPos.y, fromPos.x - vertexPos.x)

        // Compute ideal "to" joint position using target angle
        let targetRad = targetAngle * .pi / 180.0
        let idealToDir = fromDir + targetRad
        let idealToPos = CGPoint(
            x: vertexPos.x + CGFloat(cos(idealToDir)) * vertexToToLen,
            y: vertexPos.y + CGFloat(sin(idealToDir)) * vertexToToLen
        )

        // Update the "to" joint with ideal position
        idealKeypoints[tracking.to] = PoseKeypoint(
            joint: tracking.to,
            position: idealToPos,
            confidence: 1.0
        )

        // If there are child joints beyond "to" (e.g., ankle below knee),
        // propagate the offset to maintain limb continuity
        propagateChildJoints(
            parent: tracking.to,
            idealParentPos: idealToPos,
            anchorFrame: anchorFrame,
            keypoints: &idealKeypoints
        )

        return PoseFrame(keypoints: idealKeypoints, timestamp: anchorFrame.timestamp)
    }

    // MARK: - Phase Angle Mapping

    private func targetAngleForPhase(_ phase: RepPhase, profile: ExerciseFormProfile) -> Double? {
        switch phase {
        case .idle:
            return nil
        case .atTop:
            return profile.topAngle
        case .atBottom:
            return profile.bottomAngle
        case .descending:
            // Interpolate 60% toward bottom
            return profile.topAngle + (profile.bottomAngle - profile.topAngle) * 0.6
        case .ascending:
            // Interpolate 40% toward top (60% from bottom)
            return profile.bottomAngle + (profile.topAngle - profile.bottomAngle) * 0.6
        }
    }

    // MARK: - Segment Length Helpers

    private func segmentLength(from: JointName, to: JointName, anchorFrame: PoseFrame) -> CGFloat {
        // Try to use morpho measurements if available
        if let segs = segments {
            let cmLen = segmentLengthCm(from: from, to: to, segments: segs)
            if cmLen > 0 {
                // Convert cm to Vision normalized coords (approximate)
                return CGFloat(cmLen / userHeightCm) * estimatedBodyHeightInVision(anchorFrame)
            }
        }

        // Fallback: use distance from anchor frame
        return anchorFrame.distance(from: from, to: to) ?? 0.15
    }

    private func segmentLengthCm(from: JointName, to: JointName, segments: SegmentMeasurements) -> Double {
        switch (from, to) {
        case (.leftHip, .leftKnee), (.rightHip, .rightKnee):
            return segments.femurLength
        case (.leftKnee, .leftAnkle), (.rightKnee, .rightAnkle):
            return segments.tibiaLength
        case (.leftShoulder, .leftElbow), (.rightShoulder, .rightElbow):
            return segments.humerusLength
        case (.leftElbow, .leftWrist), (.rightElbow, .rightWrist):
            return segments.forearmLength
        case (.neck, .root):
            return segments.torsoLength
        default:
            return 0
        }
    }

    private func estimatedBodyHeightInVision(_ frame: PoseFrame) -> CGFloat {
        guard let neckY = frame[.neck]?.position.y,
              let ankleY = frame.midpoint(of: .leftAnkle, and: .rightAnkle)?.y else {
            return 0.5 // Default fallback
        }
        return max(0.1, abs(neckY - ankleY) / 0.87) // neck-to-ankle ≈ 87% of height
    }

    // MARK: - Child Joint Propagation

    /// Propagates position offset from a parent joint to its children in the kinematic chain.
    private func propagateChildJoints(
        parent: JointName,
        idealParentPos: CGPoint,
        anchorFrame: PoseFrame,
        keypoints: inout [JointName: PoseKeypoint]
    ) {
        let childMap: [JointName: [JointName]] = [
            .leftKnee: [.leftAnkle],
            .rightKnee: [.rightAnkle],
            .leftElbow: [.leftWrist],
            .rightElbow: [.rightWrist],
        ]

        guard let children = childMap[parent],
              let realParentPos = anchorFrame[parent]?.position else { return }

        let offset = CGPoint(
            x: idealParentPos.x - realParentPos.x,
            y: idealParentPos.y - realParentPos.y
        )

        for child in children {
            guard let realChildPos = anchorFrame[child]?.position else { continue }
            let idealChildPos = CGPoint(
                x: realChildPos.x + offset.x,
                y: realChildPos.y + offset.y
            )
            keypoints[child] = PoseKeypoint(
                joint: child,
                position: idealChildPos,
                confidence: 1.0
            )
        }
    }
}
