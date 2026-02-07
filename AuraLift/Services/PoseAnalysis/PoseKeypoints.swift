import Foundation
import CoreGraphics
import Vision

// MARK: - JointName

/// All 19 body joints tracked by Vision framework for pose estimation.
enum JointName: String, CaseIterable {
    case nose
    case leftEye
    case rightEye
    case leftEar
    case rightEar
    case leftShoulder
    case rightShoulder
    case leftElbow
    case rightElbow
    case leftWrist
    case rightWrist
    case leftHip
    case rightHip
    case leftKnee
    case rightKnee
    case leftAnkle
    case rightAnkle
    case neck
    case root

    /// Maps to the corresponding Vision framework joint name.
    var vnJointName: VNHumanBodyPoseObservation.JointName {
        switch self {
        case .nose: return .nose
        case .leftEye: return .leftEye
        case .rightEye: return .rightEye
        case .leftEar: return .leftEar
        case .rightEar: return .rightEar
        case .leftShoulder: return .leftShoulder
        case .rightShoulder: return .rightShoulder
        case .leftElbow: return .leftElbow
        case .rightElbow: return .rightElbow
        case .leftWrist: return .leftWrist
        case .rightWrist: return .rightWrist
        case .leftHip: return .leftHip
        case .rightHip: return .rightHip
        case .leftKnee: return .leftKnee
        case .rightKnee: return .rightKnee
        case .leftAnkle: return .leftAnkle
        case .rightAnkle: return .rightAnkle
        case .neck: return .neck
        case .root: return .root
        }
    }

    /// Whether this joint is a core joint required for valid pose detection.
    var isCoreJoint: Bool {
        switch self {
        case .leftShoulder, .rightShoulder, .leftHip, .rightHip, .root:
            return true
        default:
            return false
        }
    }
}

// MARK: - PoseKeypoint

/// A single detected body joint with its position and detection confidence.
struct PoseKeypoint {
    let joint: JointName
    /// Position in Vision normalized coordinates (0,0 bottom-left to 1,1 top-right).
    let position: CGPoint
    let confidence: Float

    /// Creates a PoseKeypoint from a Vision recognized point.
    static func from(vnPoint: VNRecognizedPoint, joint: JointName) -> PoseKeypoint {
        PoseKeypoint(
            joint: joint,
            position: vnPoint.location,
            confidence: vnPoint.confidence
        )
    }
}

// MARK: - PoseFrame

/// A snapshot of all detected keypoints at a specific moment in time.
struct PoseFrame {
    let keypoints: [JointName: PoseKeypoint]
    let timestamp: TimeInterval

    subscript(joint: JointName) -> PoseKeypoint? {
        keypoints[joint]
    }

    /// A pose frame is valid when all core joints are detected with sufficient confidence.
    var isValid: Bool {
        let coreJoints: [JointName] = [.leftShoulder, .rightShoulder, .leftHip, .rightHip, .root]
        return coreJoints.allSatisfy { joint in
            guard let kp = keypoints[joint] else { return false }
            return kp.confidence >= 0.3
        }
    }

    // MARK: - Geometry Utilities

    /// Calculates the angle at the vertex joint, measured from `from` to `to`, in degrees.
    func angle(vertex: JointName, from: JointName, to: JointName) -> Double? {
        guard let vPt = keypoints[vertex]?.position,
              let fPt = keypoints[from]?.position,
              let tPt = keypoints[to]?.position else { return nil }

        let v1 = CGPoint(x: fPt.x - vPt.x, y: fPt.y - vPt.y)
        let v2 = CGPoint(x: tPt.x - vPt.x, y: tPt.y - vPt.y)

        let angle1 = atan2(v1.y, v1.x)
        let angle2 = atan2(v2.y, v2.x)

        var angleDiff = (angle2 - angle1) * 180.0 / .pi
        if angleDiff < 0 { angleDiff += 360.0 }
        if angleDiff > 180.0 { angleDiff = 360.0 - angleDiff }

        return angleDiff
    }

    /// Euclidean distance between two joints in Vision normalized coordinates.
    func distance(from: JointName, to: JointName) -> CGFloat? {
        guard let p1 = keypoints[from]?.position,
              let p2 = keypoints[to]?.position else { return nil }

        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        return sqrt(dx * dx + dy * dy)
    }

    /// Midpoint between two joints.
    func midpoint(of a: JointName, and b: JointName) -> CGPoint? {
        guard let p1 = keypoints[a]?.position,
              let p2 = keypoints[b]?.position else { return nil }

        return CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
    }
}

// MARK: - SkeletonConnection

/// Defines a visual connection between two joints for skeleton overlay drawing.
struct SkeletonConnection {
    let from: JointName
    let to: JointName

    /// The 17 limb connections forming the human skeleton overlay.
    static let skeletonConnections: [SkeletonConnection] = [
        // Head
        SkeletonConnection(from: .nose, to: .leftEye),
        SkeletonConnection(from: .nose, to: .rightEye),
        SkeletonConnection(from: .leftEye, to: .leftEar),
        SkeletonConnection(from: .rightEye, to: .rightEar),
        // Neck to shoulders
        SkeletonConnection(from: .neck, to: .leftShoulder),
        SkeletonConnection(from: .neck, to: .rightShoulder),
        // Spine
        SkeletonConnection(from: .neck, to: .root),
        // Arms
        SkeletonConnection(from: .leftShoulder, to: .leftElbow),
        SkeletonConnection(from: .leftElbow, to: .leftWrist),
        SkeletonConnection(from: .rightShoulder, to: .rightElbow),
        SkeletonConnection(from: .rightElbow, to: .rightWrist),
        // Hips
        SkeletonConnection(from: .root, to: .leftHip),
        SkeletonConnection(from: .root, to: .rightHip),
        // Legs
        SkeletonConnection(from: .leftHip, to: .leftKnee),
        SkeletonConnection(from: .leftKnee, to: .leftAnkle),
        SkeletonConnection(from: .rightHip, to: .rightKnee),
        SkeletonConnection(from: .rightKnee, to: .rightAnkle),
    ]
}
