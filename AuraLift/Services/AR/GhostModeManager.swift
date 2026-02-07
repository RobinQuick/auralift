import Foundation
import SwiftUI
import Combine

// MARK: - LPParticle

/// A floating "+LP" text particle that animates upward and fades out.
struct LPParticle: Identifiable {
    let id = UUID()
    let value: Int32
    let position: CGPoint
    let timestamp: Date
}

// MARK: - GhostModeManager

/// Orchestrates Ghost Mode: owns PerfectFormAvatar, manages ghost lifecycle,
/// publishes state for the overlay. Also manages LP floating particles.
final class GhostModeManager: ObservableObject, ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {
        try? await avatar.initialize()
    }

    // MARK: - Published State

    @Published var isGhostModeEnabled: Bool = false
    @Published var ghostPoseFrame: PoseFrame?
    @Published var ghostConfig: GhostOverlayConfig = GhostOverlayConfig()
    @Published var lpParticles: [LPParticle] = []

    // MARK: - Avatar

    let avatar: PerfectFormAvatar

    // MARK: - Private State

    private var currentExerciseName: String?
    private let particleLifetime: TimeInterval = 2.0

    // MARK: - Init

    init() {
        self.avatar = PerfectFormAvatar()
    }

    // MARK: - Ghost Mode Control

    /// Starts ghost mode for a specific exercise with optional morpho measurements.
    func startGhostMode(for exerciseName: String, segments: SegmentMeasurements?, referenceFrame: PoseFrame?) {
        currentExerciseName = exerciseName
        avatar.configure(exerciseName: exerciseName, segments: segments, referenceFrame: referenceFrame)
        isGhostModeEnabled = true
    }

    /// Stops ghost mode and clears state.
    func stopGhostMode() {
        isGhostModeEnabled = false
        ghostPoseFrame = nil
        currentExerciseName = nil
    }

    /// Updates the ghost pose for the current rep phase using the user's real frame as anchor.
    func updateForPhase(_ phase: RepPhase, anchorFrame: PoseFrame) {
        guard isGhostModeEnabled else {
            ghostPoseFrame = nil
            return
        }

        ghostPoseFrame = avatar.computeIdealPoseFrame(for: phase, anchorFrame: anchorFrame)
    }

    /// Adjusts interpolation smoothing based on user tempo.
    func syncToUserTempo(bpm: Double) {
        // Reserved for future tempo-based interpolation smoothing
    }

    // MARK: - LP Particles

    /// Spawns a floating "+LP" particle near the tracked joint.
    func addLPParticle(value: Int32, nearJoint: JointName?, frame: PoseFrame?, viewSize: CGSize) {
        guard value > 0 else { return }

        var position = CGPoint(x: viewSize.width / 2, y: viewSize.height * 0.4)

        // Position near the tracked joint if available
        if let joint = nearJoint,
           let kp = frame?[joint] {
            position = CGPoint(
                x: kp.position.x * viewSize.width,
                y: (1 - kp.position.y) * viewSize.height - 30
            )
        }

        let particle = LPParticle(value: value, position: position, timestamp: Date())
        lpParticles.append(particle)
    }

    /// Removes particles older than the lifetime threshold.
    func cleanupExpiredParticles() {
        let cutoff = Date().addingTimeInterval(-particleLifetime)
        lpParticles.removeAll { $0.timestamp < cutoff }
    }
}
