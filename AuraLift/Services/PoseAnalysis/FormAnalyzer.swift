import Foundation
import CoreGraphics

// MARK: - FormAnalysisResult

/// Result of a single-frame form analysis pass.
struct FormAnalysisResult {
    let score: Double          // 0-100
    let issues: [FormIssue]
    let jointAngles: [String: Double]  // Key angle readings for debugging
    let romDegrees: Double     // Range of motion for the primary joint
    let barPathDeviation: Double // Deviation from ideal vertical path (normalized 0-1)
}

// MARK: - FormIssue

/// A specific form deviation detected during analysis.
struct FormIssue {
    let name: String           // e.g. "Knee Cave", "Back Rounding"
    let severity: IssueSeverity
    let joint: JointName       // Which joint is affected
    let message: String        // User-facing guidance

    enum IssueSeverity: Int {
        case minor = 1      // -5 points
        case moderate = 2   // -15 points
        case major = 3      // -25 points

        var penalty: Double {
            switch self {
            case .minor: return 5
            case .moderate: return 15
            case .major: return 25
            }
        }
    }
}

// MARK: - ExerciseFormProfile

/// Defines ideal joint angles and form checks for a specific exercise.
struct ExerciseFormProfile {
    let exerciseName: String
    let trackingJoint: JointName       // Primary joint for rep detection
    let trackingAngleJoints: (vertex: JointName, from: JointName, to: JointName)
    let topAngle: Double               // Angle at top of rep (extended)
    let bottomAngle: Double            // Angle at bottom of rep (contracted)
    let idealAngles: [AngleCheck]      // Ideal angle ranges to check
    let issueChecks: [IssueCheck]      // Form issue detection rules
    let barPathJoint: JointName?       // Joint to track for bar path (nil if N/A)

    struct AngleCheck {
        let name: String
        let vertex: JointName
        let from: JointName
        let to: JointName
        let idealMin: Double
        let idealMax: Double
        let weight: Double  // Contribution weight to overall score (0-1)
    }

    struct IssueCheck {
        let name: String
        let severity: FormIssue.IssueSeverity
        let joint: JointName
        let message: String
        let check: (PoseFrame) -> Bool  // Returns true if issue is detected
    }
}

// MARK: - FormAnalyzer

/// Real-time exercise form analysis engine. Evaluates joint angles against
/// exercise-specific ideal ranges and detects common form deviations.
final class FormAnalyzer: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - State

    private var currentProfile: ExerciseFormProfile?
    private var barPathXHistory: [Double] = []
    private let barPathWindowSize = 30 // ~1 second at 30fps

    // MARK: - Configuration

    /// Sets the exercise profile for form analysis.
    func configure(for exerciseName: String) {
        currentProfile = Self.profiles[exerciseName]
        barPathXHistory = []
    }

    // MARK: - Analysis

    /// Analyzes a single pose frame against the configured exercise profile.
    func analyze(_ frame: PoseFrame) -> FormAnalysisResult {
        guard let profile = currentProfile, frame.isValid else {
            return FormAnalysisResult(score: 0, issues: [], jointAngles: [:], romDegrees: 0, barPathDeviation: 0)
        }

        var totalScore = 100.0
        var issues: [FormIssue] = []
        var angles: [String: Double] = [:]

        // Evaluate ideal angle ranges
        for check in profile.idealAngles {
            guard let angle = frame.angle(vertex: check.vertex, from: check.from, to: check.to) else {
                continue
            }
            angles[check.name] = angle

            if angle >= check.idealMin && angle <= check.idealMax {
                // Perfect range — no penalty
            } else {
                // Calculate penalty based on deviation
                let deviation: Double
                if angle < check.idealMin {
                    deviation = check.idealMin - angle
                } else {
                    deviation = angle - check.idealMax
                }
                // Scale penalty: 1 degree off = minor, >15 degrees = major
                let penalty = min(check.weight * 30, deviation * check.weight * 2)
                totalScore -= penalty
            }
        }

        // Check for form issues
        for check in profile.issueChecks {
            if check.check(frame) {
                issues.append(FormIssue(
                    name: check.name,
                    severity: check.severity,
                    joint: check.joint,
                    message: check.message
                ))
                totalScore -= check.severity.penalty
            }
        }

        // ROM measurement (primary tracking joint angle)
        let rom = frame.angle(
            vertex: profile.trackingAngleJoints.vertex,
            from: profile.trackingAngleJoints.from,
            to: profile.trackingAngleJoints.to
        ) ?? 0

        // Bar path deviation
        let barDev = computeBarPathDeviation(frame: frame, profile: profile)

        return FormAnalysisResult(
            score: max(0, min(100, totalScore)),
            issues: issues,
            jointAngles: angles,
            romDegrees: rom,
            barPathDeviation: barDev
        )
    }

    // MARK: - Bar Path Deviation

    private func computeBarPathDeviation(frame: PoseFrame, profile: ExerciseFormProfile) -> Double {
        guard let trackJoint = profile.barPathJoint,
              let position = frame[trackJoint]?.position else { return 0 }

        barPathXHistory.append(Double(position.x))
        if barPathXHistory.count > barPathWindowSize {
            barPathXHistory.removeFirst()
        }

        guard barPathXHistory.count >= 5 else { return 0 }

        // Compute standard deviation of X position (ideal = straight vertical = low X variance)
        let mean = barPathXHistory.reduce(0, +) / Double(barPathXHistory.count)
        let variance = barPathXHistory.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(barPathXHistory.count)
        let stdDev = sqrt(variance)

        // Normalize: stdDev of 0.01 in Vision coords ≈ minor sway, 0.05+ = major
        return min(1.0, stdDev * 20)
    }

    /// Resets bar path tracking (call between sets).
    func resetBarPath() {
        barPathXHistory = []
    }

    // MARK: - Exercise Profiles

    static let profiles: [String: ExerciseFormProfile] = {
        var p: [String: ExerciseFormProfile] = [:]

        // --- BARBELL BACK SQUAT ---
        p["Barbell Back Squat"] = ExerciseFormProfile(
            exerciseName: "Barbell Back Squat",
            trackingJoint: .leftKnee,
            trackingAngleJoints: (vertex: .leftKnee, from: .leftHip, to: .leftAnkle),
            topAngle: 170,
            bottomAngle: 70,
            idealAngles: [
                .init(name: "Knee Flexion (L)", vertex: .leftKnee, from: .leftHip, to: .leftAnkle, idealMin: 60, idealMax: 175, weight: 0.3),
                .init(name: "Knee Flexion (R)", vertex: .rightKnee, from: .rightHip, to: .rightAnkle, idealMin: 60, idealMax: 175, weight: 0.3),
                .init(name: "Hip Hinge", vertex: .leftHip, from: .leftShoulder, to: .leftKnee, idealMin: 50, idealMax: 170, weight: 0.2),
                .init(name: "Torso Angle", vertex: .root, from: .neck, to: .leftKnee, idealMin: 40, idealMax: 90, weight: 0.2),
            ],
            issueChecks: [
                .init(name: "Knee Cave", severity: .moderate, joint: .leftKnee,
                      message: "Keep knees tracking over toes") { frame in
                    // Knee cave: knees narrower than hips at bottom of squat
                    guard let lKnee = frame[.leftKnee]?.position,
                          let rKnee = frame[.rightKnee]?.position,
                          let lHip = frame[.leftHip]?.position,
                          let rHip = frame[.rightHip]?.position else { return false }
                    let kneeWidth = abs(lKnee.x - rKnee.x)
                    let hipWidth = abs(lHip.x - rHip.x)
                    return kneeWidth < hipWidth * 0.75
                },
                .init(name: "Forward Lean", severity: .minor, joint: .neck,
                      message: "Keep chest up, avoid excessive forward lean") { frame in
                    guard let neck = frame[.neck]?.position,
                          let root = frame[.root]?.position else { return false }
                    // Excessive forward lean: neck X far in front of root X
                    return abs(neck.x - root.x) > 0.08
                },
            ],
            barPathJoint: .root
        )

        // --- BARBELL BENCH PRESS ---
        p["Barbell Bench Press"] = ExerciseFormProfile(
            exerciseName: "Barbell Bench Press",
            trackingJoint: .leftElbow,
            trackingAngleJoints: (vertex: .leftElbow, from: .leftShoulder, to: .leftWrist),
            topAngle: 170,
            bottomAngle: 75,
            idealAngles: [
                .init(name: "Elbow Flexion (L)", vertex: .leftElbow, from: .leftShoulder, to: .leftWrist, idealMin: 70, idealMax: 175, weight: 0.3),
                .init(name: "Elbow Flexion (R)", vertex: .rightElbow, from: .rightShoulder, to: .rightWrist, idealMin: 70, idealMax: 175, weight: 0.3),
                .init(name: "Shoulder Angle (L)", vertex: .leftShoulder, from: .leftHip, to: .leftElbow, idealMin: 40, idealMax: 85, weight: 0.2),
                .init(name: "Shoulder Angle (R)", vertex: .rightShoulder, from: .rightHip, to: .rightElbow, idealMin: 40, idealMax: 85, weight: 0.2),
            ],
            issueChecks: [
                .init(name: "Elbow Flare", severity: .moderate, joint: .leftElbow,
                      message: "Tuck elbows to ~45 degrees from torso") { frame in
                    guard let lShoulder = frame[.leftShoulder]?.position,
                          let rShoulder = frame[.rightShoulder]?.position,
                          let lElbow = frame[.leftElbow]?.position,
                          let rElbow = frame[.rightElbow]?.position else { return false }
                    // Elbows wider than shoulders = flare
                    let elbowWidth = abs(lElbow.x - rElbow.x)
                    let shoulderWidth = abs(lShoulder.x - rShoulder.x)
                    return elbowWidth > shoulderWidth * 1.4
                },
                .init(name: "Uneven Arms", severity: .minor, joint: .leftWrist,
                      message: "Press evenly with both arms") { frame in
                    guard let lWrist = frame[.leftWrist]?.position,
                          let rWrist = frame[.rightWrist]?.position else { return false }
                    return abs(lWrist.y - rWrist.y) > 0.04
                },
            ],
            barPathJoint: .leftWrist
        )

        // --- OVERHEAD PRESS ---
        p["Overhead Press"] = ExerciseFormProfile(
            exerciseName: "Overhead Press",
            trackingJoint: .leftElbow,
            trackingAngleJoints: (vertex: .leftElbow, from: .leftShoulder, to: .leftWrist),
            topAngle: 170,
            bottomAngle: 80,
            idealAngles: [
                .init(name: "Elbow Flexion (L)", vertex: .leftElbow, from: .leftShoulder, to: .leftWrist, idealMin: 75, idealMax: 175, weight: 0.3),
                .init(name: "Elbow Flexion (R)", vertex: .rightElbow, from: .rightShoulder, to: .rightWrist, idealMin: 75, idealMax: 175, weight: 0.3),
                .init(name: "Torso Lean", vertex: .root, from: .neck, to: .leftHip, idealMin: 160, idealMax: 180, weight: 0.4),
            ],
            issueChecks: [
                .init(name: "Excessive Back Lean", severity: .major, joint: .root,
                      message: "Avoid leaning back — brace core") { frame in
                    guard let neck = frame[.neck]?.position,
                          let root = frame[.root]?.position,
                          let hip = frame[.leftHip]?.position else { return false }
                    // Root significantly behind hips = back lean
                    return root.x - hip.x > 0.05 || neck.x - root.x > 0.06
                },
            ],
            barPathJoint: .leftWrist
        )

        // --- BARBELL ROW ---
        p["Barbell Row"] = ExerciseFormProfile(
            exerciseName: "Barbell Row",
            trackingJoint: .leftElbow,
            trackingAngleJoints: (vertex: .leftElbow, from: .leftShoulder, to: .leftWrist),
            topAngle: 50,
            bottomAngle: 160,
            idealAngles: [
                .init(name: "Elbow Flexion (L)", vertex: .leftElbow, from: .leftShoulder, to: .leftWrist, idealMin: 40, idealMax: 170, weight: 0.3),
                .init(name: "Hip Hinge", vertex: .leftHip, from: .leftShoulder, to: .leftKnee, idealMin: 60, idealMax: 120, weight: 0.4),
                .init(name: "Elbow Flexion (R)", vertex: .rightElbow, from: .rightShoulder, to: .rightWrist, idealMin: 40, idealMax: 170, weight: 0.3),
            ],
            issueChecks: [
                .init(name: "Torso Rising", severity: .moderate, joint: .neck,
                      message: "Maintain hip hinge angle throughout the row") { frame in
                    guard let angle = frame.angle(vertex: .leftHip, from: .leftShoulder, to: .leftKnee) else { return false }
                    return angle > 140 // Too upright
                },
            ],
            barPathJoint: .leftWrist
        )

        // --- ROMANIAN DEADLIFT ---
        p["Romanian Deadlift"] = ExerciseFormProfile(
            exerciseName: "Romanian Deadlift",
            trackingJoint: .leftHip,
            trackingAngleJoints: (vertex: .leftHip, from: .leftShoulder, to: .leftKnee),
            topAngle: 170,
            bottomAngle: 70,
            idealAngles: [
                .init(name: "Hip Hinge", vertex: .leftHip, from: .leftShoulder, to: .leftKnee, idealMin: 60, idealMax: 175, weight: 0.4),
                .init(name: "Knee Flexion", vertex: .leftKnee, from: .leftHip, to: .leftAnkle, idealMin: 150, idealMax: 180, weight: 0.3),
                .init(name: "Spine Neutral", vertex: .neck, from: .root, to: .nose, idealMin: 140, idealMax: 180, weight: 0.3),
            ],
            issueChecks: [
                .init(name: "Back Rounding", severity: .major, joint: .root,
                      message: "Maintain neutral spine — chest up") { frame in
                    guard let neck = frame[.neck]?.position,
                          let root = frame[.root]?.position,
                          let leftShoulder = frame[.leftShoulder]?.position else { return false }
                    // Shoulder dropping below expected line = rounding
                    let shoulderDropBelowNeck = neck.y - leftShoulder.y
                    return shoulderDropBelowNeck > 0.06
                },
                .init(name: "Excessive Knee Bend", severity: .minor, joint: .leftKnee,
                      message: "Keep knees slightly bent, not squatting") { frame in
                    guard let angle = frame.angle(vertex: .leftKnee, from: .leftHip, to: .leftAnkle) else { return false }
                    return angle < 140
                },
            ],
            barPathJoint: .leftWrist
        )

        // --- CONVENTIONAL DEADLIFT ---
        p["Conventional Deadlift"] = ExerciseFormProfile(
            exerciseName: "Conventional Deadlift",
            trackingJoint: .leftHip,
            trackingAngleJoints: (vertex: .leftHip, from: .leftShoulder, to: .leftKnee),
            topAngle: 170,
            bottomAngle: 60,
            idealAngles: [
                .init(name: "Hip Hinge", vertex: .leftHip, from: .leftShoulder, to: .leftKnee, idealMin: 55, idealMax: 175, weight: 0.3),
                .init(name: "Knee Flexion", vertex: .leftKnee, from: .leftHip, to: .leftAnkle, idealMin: 60, idealMax: 175, weight: 0.3),
                .init(name: "Spine", vertex: .root, from: .neck, to: .leftHip, idealMin: 140, idealMax: 180, weight: 0.4),
            ],
            issueChecks: [
                .init(name: "Back Rounding", severity: .major, joint: .root,
                      message: "Maintain neutral spine off the floor") { frame in
                    guard let neck = frame[.neck]?.position,
                          let root = frame[.root]?.position else { return false }
                    return abs(neck.x - root.x) > 0.10
                },
            ],
            barPathJoint: .leftWrist
        )

        // --- PULL-UP ---
        p["Pull-Up"] = ExerciseFormProfile(
            exerciseName: "Pull-Up",
            trackingJoint: .leftElbow,
            trackingAngleJoints: (vertex: .leftElbow, from: .leftShoulder, to: .leftWrist),
            topAngle: 50,
            bottomAngle: 170,
            idealAngles: [
                .init(name: "Elbow Flexion (L)", vertex: .leftElbow, from: .leftShoulder, to: .leftWrist, idealMin: 40, idealMax: 175, weight: 0.4),
                .init(name: "Elbow Flexion (R)", vertex: .rightElbow, from: .rightShoulder, to: .rightWrist, idealMin: 40, idealMax: 175, weight: 0.4),
            ],
            issueChecks: [
                .init(name: "Kipping", severity: .moderate, joint: .leftHip,
                      message: "Avoid swinging — use strict form") { frame in
                    guard let hip = frame[.leftHip]?.position,
                          let shoulder = frame[.leftShoulder]?.position else { return false }
                    // Hips far in front of shoulders = kipping
                    return hip.x - shoulder.x > 0.06
                },
            ],
            barPathJoint: nil
        )

        // --- LAT PULLDOWN ---
        p["Lat Pulldown"] = ExerciseFormProfile(
            exerciseName: "Lat Pulldown",
            trackingJoint: .leftElbow,
            trackingAngleJoints: (vertex: .leftElbow, from: .leftShoulder, to: .leftWrist),
            topAngle: 170,
            bottomAngle: 50,
            idealAngles: [
                .init(name: "Elbow Flexion (L)", vertex: .leftElbow, from: .leftShoulder, to: .leftWrist, idealMin: 40, idealMax: 175, weight: 0.4),
                .init(name: "Elbow Flexion (R)", vertex: .rightElbow, from: .rightShoulder, to: .rightWrist, idealMin: 40, idealMax: 175, weight: 0.4),
                .init(name: "Torso Lean", vertex: .root, from: .neck, to: .leftHip, idealMin: 155, idealMax: 180, weight: 0.2),
            ],
            issueChecks: [],
            barPathJoint: nil
        )

        // --- HIP THRUST ---
        p["Hip Thrust"] = ExerciseFormProfile(
            exerciseName: "Hip Thrust",
            trackingJoint: .leftHip,
            trackingAngleJoints: (vertex: .leftHip, from: .leftShoulder, to: .leftKnee),
            topAngle: 170,
            bottomAngle: 80,
            idealAngles: [
                .init(name: "Hip Extension", vertex: .leftHip, from: .leftShoulder, to: .leftKnee, idealMin: 75, idealMax: 180, weight: 0.4),
                .init(name: "Knee Angle", vertex: .leftKnee, from: .leftHip, to: .leftAnkle, idealMin: 80, idealMax: 100, weight: 0.3),
            ],
            issueChecks: [
                .init(name: "Hyperextension", severity: .minor, joint: .root,
                      message: "Avoid overarching lower back at lockout") { frame in
                    guard let angle = frame.angle(vertex: .leftHip, from: .leftShoulder, to: .leftKnee) else { return false }
                    return angle > 185
                },
            ],
            barPathJoint: nil
        )

        return p
    }()
}
