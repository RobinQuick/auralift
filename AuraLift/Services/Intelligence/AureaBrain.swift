import Foundation

// MARK: - MorphoDecision

/// Result of a morpho-constraint evaluation: ban an exercise and suggest an alternative.
struct MorphoDecision {
    let exerciseName: String
    let isBanned: Bool
    let reason: String
    let suggestedAlternative: String
}

// MARK: - CycleConstraint

/// Cycle-phase-aware training constraints for female athletes.
struct CycleConstraint {
    let rpeCap: Double
    let volumeReduction: Double // 0.20 = -20%
    let reason: String
}

// MARK: - AureaBrief

/// Pre-session intelligence summary combining readiness, cycle, and morpho data.
struct AureaBrief {
    let readinessLevel: String
    let cycleNote: String?
    let morphoWarnings: [String]
    let recommendedFocus: String
}

// MARK: - AureaBrain

/// Central decision engine that evaluates morpho constraints, cycle phase,
/// and VBT kill-switch logic. Used by WorkoutViewModel, ParetoProgramBuilder,
/// and LiveSessionAdapter for unified intelligence.
final class AureaBrain {

    // MARK: - Morpho Constraints

    /// Evaluates whether an exercise should be banned based on body proportions.
    /// Returns nil if the exercise is safe for the given measurements.
    func evaluateMorphoConstraints(
        measurements: SegmentMeasurements,
        exerciseName: String
    ) -> MorphoDecision? {
        let name = exerciseName.lowercased()

        // Long femurs relative to torso → ban Back Squat
        if measurements.femurToTorsoRatio > 0.85,
           name.contains("back squat") || name == "squat" {
            return MorphoDecision(
                exerciseName: exerciseName,
                isBanned: true,
                reason: "Your femur-to-torso ratio (\(String(format: "%.2f", measurements.femurToTorsoRatio))) exceeds the safety threshold (0.85). Back squats place excessive shear on your lumbar spine.",
                suggestedAlternative: "Leg Press or Bulgarian Split Squat"
            )
        }

        // Long humerus relative to torso → ban Barbell Bench
        if measurements.humerusToTorsoRatio > 0.52,
           name.contains("barbell bench") || (name.contains("bench press") && !name.contains("dumbbell")) {
            return MorphoDecision(
                exerciseName: exerciseName,
                isBanned: true,
                reason: "Your humerus-to-torso ratio (\(String(format: "%.2f", measurements.humerusToTorsoRatio))) exceeds 0.52. Barbell bench press creates excessive shoulder stress with long arms.",
                suggestedAlternative: "Dumbbell Bench Press"
            )
        }

        // Long tibia relative to femur → ban Deep Squat
        if measurements.tibiaToFemurRatio > 1.05,
           name.contains("squat") && !name.contains("box") && !name.contains("split") {
            return MorphoDecision(
                exerciseName: exerciseName,
                isBanned: true,
                reason: "Your tibia-to-femur ratio (\(String(format: "%.2f", measurements.tibiaToFemurRatio))) exceeds 1.05. Deep squats shift load forward onto your knees.",
                suggestedAlternative: "Box Squat"
            )
        }

        return nil
    }

    // MARK: - Cycle Constraints

    /// Evaluates cycle-phase constraints for female athletes.
    /// Returns nil if no constraint applies or cycle data is unavailable.
    func evaluateCycleConstraints(cyclePhase: CyclePhase?) -> CycleConstraint? {
        guard let phase = cyclePhase else { return nil }

        switch phase {
        case .luteal:
            return CycleConstraint(
                rpeCap: 7.0,
                volumeReduction: 0.20,
                reason: "Luteal phase: RPE capped at 7, volume reduced 20% to match hormonal recovery capacity."
            )
        case .menstrual:
            return CycleConstraint(
                rpeCap: 8.0,
                volumeReduction: 0.10,
                reason: "Menstrual phase: RPE capped at 8, volume reduced 10% for comfort."
            )
        case .follicular, .ovulatory:
            return nil
        }
    }

    // MARK: - VBT Kill Switch

    /// Returns true if velocity loss exceeds the safety threshold.
    /// When triggered: cut music, heavy haptic, voice alert, auto-finish set.
    func evaluateVBTKillSwitch(velocityLossPercent: Double) -> Bool {
        velocityLossPercent > 20.0
    }

    // MARK: - Session Brief

    /// Generates a pre-session intelligence brief combining all available data.
    func generateSessionBrief(
        readiness: Double,
        cyclePhase: CyclePhase?,
        measurements: SegmentMeasurements?,
        exercises: [String]
    ) -> AureaBrief {
        // Readiness level
        let readinessLevel: String
        if readiness >= 80 {
            readinessLevel = "Optimal — full intensity recommended"
        } else if readiness >= 60 {
            readinessLevel = "Moderate — standard training with attention to recovery"
        } else if readiness >= 35 {
            readinessLevel = "Low — reduced loads recommended"
        } else {
            readinessLevel = "Critical — volume mode activated, prioritize blood flow"
        }

        // Cycle note
        let cycleNote: String?
        if let constraint = evaluateCycleConstraints(cyclePhase: cyclePhase) {
            cycleNote = constraint.reason
        } else {
            cycleNote = nil
        }

        // Morpho warnings
        var morphoWarnings: [String] = []
        if let measures = measurements {
            for exercise in exercises {
                if let decision = evaluateMorphoConstraints(measurements: measures, exerciseName: exercise),
                   decision.isBanned {
                    morphoWarnings.append("\(exercise) → \(decision.suggestedAlternative)")
                }
            }
        }

        // Focus recommendation
        let recommendedFocus: String
        if readiness < 35 {
            recommendedFocus = "Light pump work — focus on mind-muscle connection"
        } else if readiness < 60 {
            recommendedFocus = "Moderate intensity — prioritize technique over load"
        } else {
            recommendedFocus = "Push for progressive overload — conditions are favorable"
        }

        return AureaBrief(
            readinessLevel: readinessLevel,
            cycleNote: cycleNote,
            morphoWarnings: morphoWarnings,
            recommendedFocus: recommendedFocus
        )
    }
}
