import Foundation
import CoreData

// MARK: - BiomechanicsEngine

/// Assesses exercise risk based on the user's limb ratios and generates
/// personalized biomechanical recommendations.
final class BiomechanicsEngine: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Risk Assessment (Single Exercise)

    /// Evaluates injury risk for a given exercise based on user morphology.
    func assessRisk(for exerciseName: String, measurements: SegmentMeasurements) -> ExerciseRisk {
        guard let rule = Self.riskRules[exerciseName] else {
            return .optimal
        }
        return rule(measurements)
    }

    // MARK: - Risk Assessment (All Exercises)

    /// Computes risk levels for all exercises based on the user's measurements.
    /// - Returns: Dictionary mapping Exercise UUID to ExerciseRisk.
    func assessAllExercises(
        measurements: SegmentMeasurements,
        exercises: [Exercise]
    ) -> [UUID: ExerciseRisk] {
        var riskMap: [UUID: ExerciseRisk] = [:]

        for exercise in exercises {
            let risk = assessRisk(for: exercise.name, measurements: measurements)
            riskMap[exercise.id] = risk
        }

        return riskMap
    }

    // MARK: - Biomechanical Summary

    /// Generates a natural-language summary of the user's biomechanical profile.
    func generateSummary(_ measurements: SegmentMeasurements, morphotype: Morphotype) -> String {
        var insights: [String] = []

        // Pressing mechanics
        if measurements.humerusToTorsoRatio < 0.73 {
            insights.append("Short levers give you a mechanical advantage on pressing movements.")
        } else if measurements.humerusToTorsoRatio > 0.82 {
            insights.append("Longer arms increase ROM on pressing movements. Focus on controlled eccentrics.")
        }

        // Squat mechanics
        if measurements.femurToTorsoRatio < 0.82 {
            insights.append("Your proportions favour strong squat mechanics with an upright torso.")
        } else if measurements.femurToTorsoRatio > 0.92 {
            insights.append("Longer femurs may increase forward lean on squats. Consider heel elevation or front squat variants.")
        }

        // Deadlift mechanics
        if measurements.armSpanToHeightRatio > 1.03 {
            insights.append("Long reach gives you excellent deadlift leverage — shorter bar path off the floor.")
        } else if measurements.armSpanToHeightRatio < 0.97 {
            insights.append("Shorter reach increases deadlift difficulty off the floor. Sumo or trap bar may suit you better.")
        }

        // V-taper / structure
        if measurements.shoulderToHipRatio > 1.40 {
            insights.append("Wide clavicle structure provides a strong V-taper foundation.")
        }

        if insights.isEmpty {
            insights.append("Your proportions are well-balanced across major movement patterns.")
        }

        return insights.joined(separator: " ")
    }

    // MARK: - Alternative Suggestions

    /// Suggests exercise alternatives that better match the user's morphology.
    func suggestAlternatives(
        for exerciseName: String,
        measurements: SegmentMeasurements
    ) -> [String] {
        guard let alts = Self.alternativeMap[exerciseName] else { return [] }
        return alts
    }

    // MARK: - Risk Rules

    /// Exercise-specific risk rules based on biomechanical research.
    /// Each rule maps limb ratio thresholds to an ExerciseRisk level.
    private static let riskRules: [String: (SegmentMeasurements) -> ExerciseRisk] = [
        // Lower body compounds
        "Barbell Back Squat": { m in
            if m.femurToTorsoRatio > 1.05 { return .highRisk }
            if m.femurToTorsoRatio > 0.92 { return .caution }
            return .optimal
        },
        "Barbell Front Squat": { m in
            // Front squat is generally safer for long-femured lifters
            if m.femurToTorsoRatio > 1.10 { return .caution }
            return .optimal
        },
        "Conventional Deadlift": { m in
            // Short arms + long torso = high stress on lower back
            if m.armSpanToHeightRatio < 0.96 && m.femurToTorsoRatio < 0.78 {
                return .highRisk
            }
            if m.armSpanToHeightRatio < 1.0 { return .caution }
            return .optimal
        },
        "Sumo Deadlift": { m in
            if m.hipWidth < 25 && m.shoulderToHipRatio > 1.50 { return .caution }
            return .optimal
        },
        "Bulgarian Split Squat": { m in
            if m.femurToTorsoRatio > 1.05 { return .caution }
            return .optimal
        },

        // Upper body pressing
        "Barbell Bench Press": { m in
            if m.humerusToTorsoRatio > 0.90 { return .highRisk }
            if m.humerusToTorsoRatio > 0.82 { return .caution }
            return .optimal
        },
        "Incline Barbell Press": { m in
            if m.humerusToTorsoRatio > 0.90 { return .highRisk }
            if m.humerusToTorsoRatio > 0.82 { return .caution }
            return .optimal
        },
        "Dumbbell Bench Press": { m in
            if m.humerusToTorsoRatio > 0.92 { return .caution }
            return .optimal
        },
        "Overhead Press": { m in
            if m.humerusToTorsoRatio > 0.90 { return .highRisk }
            if m.humerusToTorsoRatio > 0.82 { return .caution }
            return .optimal
        },
        "Dips (Chest)": { m in
            // Dips are inherently risky for long-armed lifters (deep shoulder stress)
            if m.humerusToTorsoRatio > 0.85 { return .highRisk }
            return .caution
        },

        // Upper body pulling
        "Barbell Row": { m in
            // Long femurs → harder to maintain hip hinge position
            if m.femurToTorsoRatio > 1.0 { return .caution }
            return .optimal
        },
        "Pull-Up": { m in
            if m.armSpanToHeightRatio < 0.97 { return .caution }
            return .optimal
        },
        "T-Bar Row": { m in
            if m.femurToTorsoRatio > 1.0 { return .caution }
            return .optimal
        },
    ]

    // MARK: - Alternative Exercise Map

    /// Maps exercises to their morphology-friendlier alternatives.
    private static let alternativeMap: [String: [String]] = [
        "Barbell Back Squat": ["Barbell Front Squat", "Leg Press", "Bulgarian Split Squat"],
        "Conventional Deadlift": ["Sumo Deadlift", "Romanian Deadlift", "Hip Thrust"],
        "Barbell Bench Press": ["Dumbbell Bench Press", "Cable Fly"],
        "Incline Barbell Press": ["Dumbbell Bench Press", "Cable Fly"],
        "Overhead Press": ["Lateral Raise", "Cable Lateral Raise"],
        "Dips (Chest)": ["Cable Fly", "Dumbbell Bench Press"],
        "Barbell Row": ["Seated Cable Row", "Lat Pulldown"],
        "Pull-Up": ["Lat Pulldown", "Seated Cable Row"],
        "T-Bar Row": ["Seated Cable Row", "Lat Pulldown"],
    ]

    // MARK: - Exercise Risk Statistics

    /// Groups exercises by their risk level for display.
    static func groupByRisk(
        exercises: [Exercise],
        riskMap: [UUID: ExerciseRisk]
    ) -> (optimal: [Exercise], caution: [Exercise], highRisk: [Exercise]) {
        var optimal: [Exercise] = []
        var caution: [Exercise] = []
        var highRisk: [Exercise] = []

        for exercise in exercises {
            let risk = riskMap[exercise.id] ?? .optimal
            switch risk {
            case .optimal: optimal.append(exercise)
            case .caution: caution.append(exercise)
            case .highRisk: highRisk.append(exercise)
            }
        }

        return (optimal, caution, highRisk)
    }
}
