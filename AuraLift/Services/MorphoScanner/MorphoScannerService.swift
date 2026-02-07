import Foundation
import CoreGraphics

// MARK: - Morphotype

/// Classification of the user's body proportions based on limb ratios.
enum Morphotype: String, CaseIterable {
    case longLimbed = "Long-Limbed"
    case shortTorso = "Short Torso"
    case longTorso = "Long Torso"
    case proportional = "Proportional"
    case longArms = "Long Arms"
    case shortArms = "Short Arms"

    var description: String {
        switch self {
        case .longLimbed:
            return "Longer limbs relative to torso. Pulling exercises are mechanically advantaged."
        case .shortTorso:
            return "Shorter torso with longer legs. May need stance adjustments on squats."
        case .longTorso:
            return "Longer torso with shorter limbs. Strong pressing and squatting mechanics."
        case .proportional:
            return "Balanced proportions. No significant leverage advantages or disadvantages."
        case .longArms:
            return "Longer arms relative to torso. Excellent deadlift and row mechanics."
        case .shortArms:
            return "Shorter arms relative to torso. Mechanical advantage on pressing movements."
        }
    }
}

// MARK: - SegmentMeasurements

/// All computed limb segment lengths (in cm) and biomechanical ratios.
struct SegmentMeasurements {
    // Absolute lengths (cm)
    let torsoLength: Double
    let femurLengthL: Double
    let femurLengthR: Double
    let tibiaLengthL: Double
    let tibiaLengthR: Double
    let humerusLengthL: Double
    let humerusLengthR: Double
    let forearmLengthL: Double
    let forearmLengthR: Double
    let shoulderWidth: Double
    let hipWidth: Double
    let armSpan: Double
    let heightCm: Double

    // Averaged segments
    var femurLength: Double { (femurLengthL + femurLengthR) / 2.0 }
    var tibiaLength: Double { (tibiaLengthL + tibiaLengthR) / 2.0 }
    var humerusLength: Double { (humerusLengthL + humerusLengthR) / 2.0 }
    var forearmLength: Double { (forearmLengthL + forearmLengthR) / 2.0 }

    // Ratios
    var femurToTorsoRatio: Double {
        guard torsoLength > 0 else { return 0 }
        return femurLength / torsoLength
    }

    var tibiaToFemurRatio: Double {
        guard femurLength > 0 else { return 0 }
        return tibiaLength / femurLength
    }

    var humerusToTorsoRatio: Double {
        guard torsoLength > 0 else { return 0 }
        return humerusLength / torsoLength
    }

    var armSpanToHeightRatio: Double {
        guard heightCm > 0 else { return 0 }
        return armSpan / heightCm
    }

    var shoulderToHipRatio: Double {
        guard hipWidth > 0 else { return 0 }
        return shoulderWidth / hipWidth
    }
}

// MARK: - Population Averages

/// Reference values for morphotype classification.
enum PopulationAverages {
    static let femurToTorso: Double = 0.85
    static let tibiaToFemur: Double = 0.80
    static let humerusToTorso: Double = 0.75
    static let armSpanToHeight: Double = 1.00
    static let shoulderToHip: Double = 1.30
}

// MARK: - MorphoScannerService

/// Computes limb segment lengths, biomechanical ratios, and morphotype
/// classification from captured T-pose frames and the user's height.
final class MorphoScannerService: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - T-Pose Validation

    /// Returns a confidence score (0.0-1.0) for how well the pose matches a T-pose.
    func tposeConfidence(_ frame: PoseFrame) -> Double {
        guard frame.isValid else { return 0 }

        var score = 0.0
        var checks = 0.0

        // Check arms are roughly horizontal (angle at elbow ~160-180)
        if let leftElbowAngle = frame.angle(vertex: .leftElbow, from: .leftShoulder, to: .leftWrist) {
            checks += 1
            if leftElbowAngle >= 150 { score += 1 }
            else if leftElbowAngle >= 130 { score += 0.5 }
        }

        if let rightElbowAngle = frame.angle(vertex: .rightElbow, from: .rightShoulder, to: .rightWrist) {
            checks += 1
            if rightElbowAngle >= 150 { score += 1 }
            else if rightElbowAngle >= 130 { score += 0.5 }
        }

        // Check arms are extended from shoulders (shoulder angle ~80-100 from torso)
        if let leftShoulderAngle = frame.angle(vertex: .leftShoulder, from: .leftHip, to: .leftElbow) {
            checks += 1
            if leftShoulderAngle >= 70 && leftShoulderAngle <= 120 { score += 1 }
            else if leftShoulderAngle >= 50 && leftShoulderAngle <= 140 { score += 0.5 }
        }

        if let rightShoulderAngle = frame.angle(vertex: .rightShoulder, from: .rightHip, to: .rightElbow) {
            checks += 1
            if rightShoulderAngle >= 70 && rightShoulderAngle <= 120 { score += 1 }
            else if rightShoulderAngle >= 50 && rightShoulderAngle <= 140 { score += 0.5 }
        }

        // Check body is upright (shoulders above hips, hips above knees)
        if let shoulderY = frame.midpoint(of: .leftShoulder, and: .rightShoulder)?.y,
           let hipY = frame.midpoint(of: .leftHip, and: .rightHip)?.y,
           let kneeY = frame.midpoint(of: .leftKnee, and: .rightKnee)?.y {
            checks += 1
            // In Vision coords, higher y = higher in frame
            if shoulderY > hipY && hipY > kneeY { score += 1 }
            else if shoulderY > hipY { score += 0.5 }
        }

        // Check all limb endpoints are detected
        let limbEndpoints: [JointName] = [.leftWrist, .rightWrist, .leftAnkle, .rightAnkle]
        let detectedEndpoints = limbEndpoints.filter { joint in
            guard let kp = frame[joint] else { return false }
            return kp.confidence >= 0.3
        }
        checks += 1
        score += Double(detectedEndpoints.count) / Double(limbEndpoints.count)

        guard checks > 0 else { return 0 }
        return score / checks
    }

    /// Quick boolean check for T-pose validity (confidence >= 0.7).
    func isTpose(_ frame: PoseFrame) -> Bool {
        tposeConfidence(frame) >= 0.7
    }

    // MARK: - Multi-Frame Averaging

    /// Averages joint positions across multiple frames for noise reduction.
    /// Only includes joints present in >= 80% of frames.
    func averageKeypoints(_ frames: [PoseFrame]) -> [JointName: CGPoint] {
        guard !frames.isEmpty else { return [:] }

        let threshold = Int(Double(frames.count) * 0.8)
        var sums: [JointName: (x: Double, y: Double, count: Int)] = [:]

        for frame in frames {
            for (joint, kp) in frame.keypoints where kp.confidence >= 0.3 {
                var entry = sums[joint, default: (x: 0, y: 0, count: 0)]
                entry.x += Double(kp.position.x)
                entry.y += Double(kp.position.y)
                entry.count += 1
                sums[joint] = entry
            }
        }

        var result: [JointName: CGPoint] = [:]
        for (joint, entry) in sums where entry.count >= threshold {
            result[joint] = CGPoint(
                x: entry.x / Double(entry.count),
                y: entry.y / Double(entry.count)
            )
        }

        return result
    }

    // MARK: - Segment Computation

    /// Computes all body segment lengths and ratios from averaged pose frames.
    /// - Parameters:
    ///   - frames: Array of T-pose PoseFrames (typically 15).
    ///   - heightCm: User's height in centimeters for calibration.
    /// - Returns: SegmentMeasurements or nil if insufficient data.
    func computeMeasurements(frames: [PoseFrame], heightCm: Double) -> SegmentMeasurements? {
        let averaged = averageKeypoints(frames)

        // Require minimum joints for computation
        let requiredJoints: [JointName] = [
            .neck, .root,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]

        for joint in requiredJoints {
            guard averaged[joint] != nil else { return nil }
        }

        // Compute normalized body height for scale factor
        guard let leftAnkle = averaged[.leftAnkle],
              let rightAnkle = averaged[.rightAnkle],
              let neckPos = averaged[.neck] else { return nil }
        let anklesMidY = (leftAnkle.y + rightAnkle.y) / 2.0
        let headY = neckPos.y  // neck as top reference
        let normalizedBodyHeight = abs(headY - anklesMidY)

        guard normalizedBodyHeight > 0.01 else { return nil }

        let scaleFactor = heightCm / normalizedBodyHeight

        // Helper to compute distance between two averaged points
        func dist(_ a: JointName, _ b: JointName) -> Double {
            guard let pA = averaged[a], let pB = averaged[b] else { return 0 }
            let dx = Double(pB.x - pA.x)
            let dy = Double(pB.y - pA.y)
            return sqrt(dx * dx + dy * dy) * scaleFactor
        }

        let torso = dist(.neck, .root)
        let femurL = dist(.leftHip, .leftKnee)
        let femurR = dist(.rightHip, .rightKnee)
        let tibiaL = dist(.leftKnee, .leftAnkle)
        let tibiaR = dist(.rightKnee, .rightAnkle)
        let humerusL = dist(.leftShoulder, .leftElbow)
        let humerusR = dist(.rightShoulder, .rightElbow)
        let forearmL = dist(.leftElbow, .leftWrist)
        let forearmR = dist(.rightElbow, .rightWrist)
        let shoulders = dist(.leftShoulder, .rightShoulder)
        let hips = dist(.leftHip, .rightHip)
        let span = dist(.leftWrist, .leftElbow)
            + dist(.leftElbow, .leftShoulder)
            + dist(.leftShoulder, .rightShoulder)
            + dist(.rightShoulder, .rightElbow)
            + dist(.rightElbow, .rightWrist)

        return SegmentMeasurements(
            torsoLength: torso,
            femurLengthL: femurL,
            femurLengthR: femurR,
            tibiaLengthL: tibiaL,
            tibiaLengthR: tibiaR,
            humerusLengthL: humerusL,
            humerusLengthR: humerusR,
            forearmLengthL: forearmL,
            forearmLengthR: forearmR,
            shoulderWidth: shoulders,
            hipWidth: hips,
            armSpan: span,
            heightCm: heightCm
        )
    }

    // MARK: - Morphotype Classification

    /// Classifies the user's body type based on the most dominant ratio deviation.
    func classifyMorphotype(_ measurements: SegmentMeasurements) -> Morphotype {
        let femurDev = measurements.femurToTorsoRatio - PopulationAverages.femurToTorso
        let humerusDev = measurements.humerusToTorsoRatio - PopulationAverages.humerusToTorso
        let armSpanDev = measurements.armSpanToHeightRatio - PopulationAverages.armSpanToHeight

        // High femur/torso + high humerus/torso → long-limbed
        if femurDev > 0.08 && humerusDev > 0.06 {
            return .longLimbed
        }

        // High femur/torso alone → short torso
        if femurDev > 0.10 {
            return .shortTorso
        }

        // Low femur/torso → long torso
        if femurDev < -0.10 {
            return .longTorso
        }

        // High arm span → long arms
        if armSpanDev > 0.04 || humerusDev > 0.08 {
            return .longArms
        }

        // Low arm span → short arms
        if armSpanDev < -0.04 || humerusDev < -0.08 {
            return .shortArms
        }

        return .proportional
    }

    // MARK: - Height Estimation

    /// Estimates the user's height from pose proportions without known height input.
    /// Uses the empirical relationship between head-to-ankle span and actual height.
    /// Head height ≈ 1/7.5 of total height (artistic canon), neck is ~0.87 of head top.
    func estimateHeight(frames: [PoseFrame]) -> Double? {
        let averaged = averageKeypoints(frames)

        guard let neckY = averaged[.neck]?.y,
              let leftAnkleY = averaged[.leftAnkle]?.y,
              let rightAnkleY = averaged[.rightAnkle]?.y else { return nil }

        let anklesMidY = (leftAnkleY + rightAnkleY) / 2.0
        let bodySpanVision = abs(Double(neckY - anklesMidY))

        guard bodySpanVision > 0.05 else { return nil }

        // Neck-to-ankle ≈ 87% of total height (head adds ~13%)
        // Average camera framing places the user at ~60% of vertical frame
        // In normalized Vision coords (0-1), this span maps to real body proportion
        // Empirical multiplier: neck-to-ankle / 0.87 = full height in same units
        let fullBodySpanVision = bodySpanVision / 0.87

        // We can't get absolute height without a reference, but we can estimate
        // using anthropometric ratios if we have no prior data.
        // Use arm span as a cross-check (arm span ≈ height for most adults)
        if let leftWristX = averaged[.leftWrist]?.x,
           let rightWristX = averaged[.rightWrist]?.x {
            let armSpanVision = abs(Double(rightWristX - leftWristX))
            if armSpanVision > 0.05 {
                // armSpan ≈ height → use as calibration
                // Average of body span and arm span estimate
                let heightFromBody = fullBodySpanVision
                let heightFromArms = armSpanVision / 0.95 // wrist-to-wrist ≈ 95% arm span
                let avgSpan = (heightFromBody + heightFromArms) / 2.0
                // Typical frame: person is ~60% of vertical → 1.0 vision unit ≈ height/0.6
                // But we return in relative units; absolute requires external reference
                return avgSpan * 280 // Rough cm estimate (calibrated for typical selfie distance)
            }
        }

        return fullBodySpanVision * 280
    }

    // MARK: - Body Fat Estimation

    /// Estimates body fat percentage from silhouette proportions.
    /// Uses the relationship between shoulder-to-hip ratio and waist indicators.
    /// Based on Hodgdon-Beckett Navy method adapted for visual estimation.
    func estimateBodyFat(measurements: SegmentMeasurements, biologicalSex: String?) -> Double {
        let shoulderHipRatio = measurements.shoulderToHipRatio

        // Waist estimation from hip width + torso length ratio
        // Wider hips relative to shoulders correlates with higher body fat
        let waistIndicator = measurements.hipWidth / max(1, measurements.shoulderWidth)

        let isFemale = biologicalSex?.lowercased() == "female"

        if isFemale {
            // Female body fat estimation
            // Healthy range: 18-28%, athletic: 14-20%
            // Higher waist indicator → higher BF
            if waistIndicator >= 0.95 {
                return min(40, 22 + (waistIndicator - 0.95) * 60) // Wider hips
            } else if waistIndicator >= 0.80 {
                return 18 + (waistIndicator - 0.80) * 26.7
            } else {
                return max(12, 18 - (0.80 - waistIndicator) * 30)
            }
        } else {
            // Male body fat estimation
            // Healthy range: 10-20%, athletic: 6-13%
            // Lower S/H ratio + higher waist indicator → higher BF
            if shoulderHipRatio >= 1.45 {
                // V-taper → lower BF estimate
                let base = 10.0
                let waistPenalty = max(0, waistIndicator - 0.70) * 30
                return min(25, base + waistPenalty)
            } else if shoulderHipRatio >= 1.25 {
                let base = 14.0
                let waistPenalty = max(0, waistIndicator - 0.72) * 35
                return min(30, base + waistPenalty)
            } else {
                let base = 18.0
                let waistPenalty = max(0, waistIndicator - 0.75) * 40
                return min(35, base + waistPenalty)
            }
        }
    }

    /// Estimates waist circumference from visual proportions and known height.
    func estimateWaist(measurements: SegmentMeasurements) -> Double {
        // Waist ≈ hip width × 2.2 (front view to circumference factor)
        // Adjusted by torso proportions
        let circumferenceFactor = 2.2
        return measurements.hipWidth * circumferenceFactor * 0.92 // Waist slightly narrower than hips
    }

    // MARK: - Golden Ratio Engine

    /// Greek Statue ideal proportions (based on classical aesthetics / Steve Reeves standards).
    /// All ratios are relative to specific body measurements.
    static let goldenRatioIdeal = GoldenRatioIdeal(
        shoulderToWaist: 1.618,        // Golden ratio
        chestToWaist: 1.40,             // Broad chest, narrow waist
        shoulderToHip: 1.53,            // V-taper
        armSpanToHeight: 1.00,          // Da Vinci proportions
        armCircToNeckCirc: 1.0,         // Arms = neck circumference (Reeves)
        calfToNeckCirc: 1.0,            // Calves = neck circumference (Reeves)
        thighToWaist: 0.75,             // Quads proportional to waist
        idealBodyFat: 10.0              // Male aesthetic ideal; female = 18%
    )

    /// Computes how close the user's proportions are to Greek ideal.
    /// Returns a score from 0 (far from ideal) to 100 (perfect Greek proportions).
    func goldenRatioScore(measurements: SegmentMeasurements, bodyFat: Double, biologicalSex: String?) -> GoldenRatioResult {
        let ideal = Self.goldenRatioIdeal
        let isFemale = biologicalSex?.lowercased() == "female"

        var deviations: [GoldenRatioDeviation] = []

        // 1. Shoulder to hip ratio (V-taper)
        let idealSH = isFemale ? 1.35 : ideal.shoulderToHip
        let shDev = ratioDeviation(
            actual: measurements.shoulderToHipRatio,
            ideal: idealSH,
            name: "Shoulder-to-Hip (V-Taper)",
            muscleGroups: ["Side Delts", "Upper Lats", "Lower Lats"]
        )
        deviations.append(shDev)

        // 2. Shoulder width to waist (approximated by hip width × factor)
        let estimatedWaist = measurements.hipWidth * 0.92
        let actualSW = estimatedWaist > 0 ? measurements.shoulderWidth / estimatedWaist : 0
        let idealSW = isFemale ? 1.40 : ideal.shoulderToWaist
        let swDev = ratioDeviation(
            actual: actualSW,
            ideal: idealSW,
            name: "Shoulder-to-Waist (Golden Ratio)",
            muscleGroups: ["Side Delts", "Obliques", "Abs"]
        )
        deviations.append(swDev)

        // 3. Arm span to height
        let asDev = ratioDeviation(
            actual: measurements.armSpanToHeightRatio,
            ideal: ideal.armSpanToHeight,
            name: "Arm Span-to-Height (Da Vinci)",
            muscleGroups: [] // Skeletal, not trainable
        )
        deviations.append(asDev)

        // 4. Body fat deviation
        let idealBF = isFemale ? 18.0 : ideal.idealBodyFat
        let bfDevPercent = bodyFat > 0 ? abs(bodyFat - idealBF) / idealBF : 0
        let bfDev = GoldenRatioDeviation(
            ratioName: "Body Fat",
            actualValue: bodyFat,
            idealValue: idealBF,
            deviationPercent: bfDevPercent,
            muscleGroupsToTrain: bodyFat > idealBF ? ["Abs", "Obliques"] : [],
            status: bfDevPercent <= 0.10 ? .ideal : (bfDevPercent <= 0.30 ? .close : .needsWork)
        )
        deviations.append(bfDev)

        // Overall score: weighted average of closeness (100 = perfect)
        let scores = deviations.map { max(0, 100 - $0.deviationPercent * 200) }
        let overallScore = scores.reduce(0, +) / Double(scores.count)

        // Priority muscles: collect from deviations that need work
        let priorityMuscles = deviations
            .filter { $0.status == .needsWork }
            .flatMap { $0.muscleGroupsToTrain }

        return GoldenRatioResult(
            overallScore: min(100, max(0, overallScore)),
            deviations: deviations,
            priorityMuscleGroups: Array(Set(priorityMuscles)),
            actionableSummary: generateActionableSummary(deviations: deviations, bodyFat: bodyFat, idealBF: idealBF)
        )
    }

    private func ratioDeviation(
        actual: Double,
        ideal: Double,
        name: String,
        muscleGroups: [String]
    ) -> GoldenRatioDeviation {
        guard ideal > 0 else {
            return GoldenRatioDeviation(ratioName: name, actualValue: actual, idealValue: ideal,
                                        deviationPercent: 0, muscleGroupsToTrain: [], status: .ideal)
        }
        let dev = abs(actual - ideal) / ideal
        let status: GoldenRatioStatus
        if dev <= 0.05 { status = .ideal }
        else if dev <= 0.15 { status = .close }
        else { status = .needsWork }

        return GoldenRatioDeviation(
            ratioName: name,
            actualValue: actual,
            idealValue: ideal,
            deviationPercent: dev,
            muscleGroupsToTrain: status == .needsWork ? muscleGroups : [],
            status: status
        )
    }

    private func generateActionableSummary(deviations: [GoldenRatioDeviation], bodyFat: Double, idealBF: Double) -> String {
        let needsWork = deviations.filter { $0.status == .needsWork }
        if needsWork.isEmpty {
            return "Your proportions are close to the Greek ideal. Maintain your current training balance."
        }

        var parts: [String] = []
        if bodyFat > idealBF + 3 {
            let deficit = Int(bodyFat - idealBF)
            parts.append("You are at \(Int(bodyFat))% body fat. To reach the Greek ideal, reduce body fat by ~\(deficit)%.")
        }

        let muscleNeeds = needsWork.flatMap { $0.muscleGroupsToTrain }
        if !muscleNeeds.isEmpty {
            let unique = Array(Set(muscleNeeds))
            parts.append("Prioritize: \(unique.joined(separator: ", ")).")
        }

        return parts.joined(separator: " ")
    }

    // MARK: - Serialization

    /// Encodes averaged keypoint positions as JSON for CoreData rawPoseData storage.
    func serializePoseData(_ frames: [PoseFrame]) -> Data? {
        let averaged = averageKeypoints(frames)
        var dict: [String: [String: Double]] = [:]

        for (joint, point) in averaged {
            dict[joint.rawValue] = ["x": Double(point.x), "y": Double(point.y)]
        }

        return try? JSONSerialization.data(withJSONObject: dict, options: [])
    }
}

// MARK: - Golden Ratio Types

/// Ideal body proportions based on Greek classical aesthetics.
struct GoldenRatioIdeal {
    let shoulderToWaist: Double
    let chestToWaist: Double
    let shoulderToHip: Double
    let armSpanToHeight: Double
    let armCircToNeckCirc: Double
    let calfToNeckCirc: Double
    let thighToWaist: Double
    let idealBodyFat: Double
}

/// Result of Golden Ratio comparison.
struct GoldenRatioResult {
    let overallScore: Double              // 0-100
    let deviations: [GoldenRatioDeviation]
    let priorityMuscleGroups: [String]    // Muscles to focus on
    let actionableSummary: String         // "Tu es à 14% de gras..."
}

/// Individual ratio deviation from ideal.
struct GoldenRatioDeviation {
    let ratioName: String
    let actualValue: Double
    let idealValue: Double
    let deviationPercent: Double          // 0.0 to 1.0+
    let muscleGroupsToTrain: [String]
    let status: GoldenRatioStatus
}

/// How close a ratio is to the Greek ideal.
enum GoldenRatioStatus: String {
    case ideal = "Ideal"         // Within 5%
    case close = "Close"         // Within 15%
    case needsWork = "Needs Work" // >15% off
}
