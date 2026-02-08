import Foundation
import CoreData

// MARK: - ExerciseSwapSuggestion

/// A suggested alternative exercise with rationale.
struct ExerciseSwapSuggestion: Identifiable {
    let id = UUID()
    let exercise: Exercise
    let suggestedWeight: Double
    let suggestedReps: String
    let whyMessage: String
    let morphoFit: MorphoFit

    enum MorphoFit: String {
        case ideal = "Ideal"
        case good = "Good"
        case acceptable = "OK"

        var displayName: String { rawValue }
    }
}

// MARK: - SessionAdaptation

/// Real-time session modification when recovery is low.
struct SessionAdaptation {
    let mode: SessionMode
    let weightReduction: Double // 0.20 = -20%
    let repAdjustment: Int // +2 reps in volume mode
    let tempoAdjustment: String
    let whyMessage: String

    var adjustedWeight: (Double) -> Double {
        { original in original * (1.0 - self.weightReduction) }
    }

    /// Adjusts a rep range string (e.g. "8-12" → "10-14" with +2 adjustment).
    func adjustedReps(_ originalReps: String) -> String {
        guard repAdjustment > 0 else { return originalReps }
        let parts = originalReps.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2 else { return originalReps }
        return "\(parts[0] + repAdjustment)-\(parts[1] + repAdjustment)"
    }
}

// MARK: - LiveSessionAdapter

/// Provides real-time exercise swaps and auto-regulation during a workout.
final class LiveSessionAdapter {

    private let overloadManager = OverloadManager()

    // MARK: - Suggest Swaps

    /// Returns up to 3 alternative exercises for the given exercise.
    func suggestSwaps(
        for exercise: Exercise,
        weight: Double,
        reps: Int,
        targetRPE: Double,
        gymProfile: GymProfile,
        measurements: SegmentMeasurements?,
        context: NSManagedObjectContext
    ) -> [ExerciseSwapSuggestion] {
        guard let primaryMuscle = exercise.primaryMuscle else { return [] }

        let request = NSFetchRequest<Exercise>(entityName: "Exercise")
        request.predicate = NSPredicate(
            format: "primaryMuscle ==[c] %@ AND id != %@",
            primaryMuscle, exercise.id as CVarArg
        )
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        guard let candidates = try? context.fetch(request) else { return [] }

        let equipment = gymProfile.equipmentList
        let available = candidates.filter { ex in
            guard let eqType = ex.equipmentType else { return true }
            return equipment.isEmpty || equipment.contains(eqType)
        }

        // Score and pick top 3
        let scored = available.prefix(10).map { candidate -> (Exercise, Double, ExerciseSwapSuggestion.MorphoFit) in
            var score: Double = 50

            // Prefer different equipment type for variety
            if candidate.equipmentType != exercise.equipmentType {
                score += 10
            }

            // Prefer stretch-position exercises
            if candidate.stretchPositionBonus {
                score += 15
            }

            // Prefer low-risk exercises
            if candidate.riskLevel == "optimal" {
                score += 10
            }

            // Prefer same resistance profile (biomechanical matching)
            if let origProfile = exercise.value(forKey: "resistanceProfile") as? String,
               let candProfile = candidate.value(forKey: "resistanceProfile") as? String,
               origProfile == candProfile {
                score += 12
            }

            // Morpho fit
            let morphoFit = evaluateMorphoFit(candidate, measurements: measurements)
            switch morphoFit {
            case .ideal: score += 20
            case .good: score += 10
            case .acceptable: break
            }

            return (candidate, score, morphoFit)
        }
        .sorted { $0.1 > $1.1 }

        return scored.prefix(3).map { candidate, _, morphoFit in
            let (newWeight, newReps) = recalculateReps(
                original: exercise,
                new: candidate,
                weight: weight,
                reps: reps,
                targetRPE: targetRPE
            )

            return ExerciseSwapSuggestion(
                exercise: candidate,
                suggestedWeight: newWeight,
                suggestedReps: newReps,
                whyMessage: generateSwapReason(original: exercise, replacement: candidate, morphoFit: morphoFit),
                morphoFit: morphoFit
            )
        }
    }

    // MARK: - Auto-Reg Check

    /// Checks if the session should be adapted based on readiness.
    /// Neo-Coach auto-reg: <35% → Volume Mode (-20% load, +2 reps).
    func checkAutoReg(
        readinessScore: Double,
        cyclePhase: CyclePhase?,
        deload: Bool
    ) -> SessionAdaptation? {
        guard !deload else { return nil }

        // Critical recovery: Volume Mode — reduce load, increase reps for blood flow
        if readinessScore < 35 {
            return SessionAdaptation(
                mode: .volume,
                weightReduction: 0.20,
                repAdjustment: 2,
                tempoAdjustment: "3-1-2",
                whyMessage: "Recovery is critically low (\(Int(readinessScore))%). Volume mode: -20% load, +2 reps — stimulate recovery through blood flow without heavy stress."
            )
        }

        // Low recovery: moderate reduction
        if readinessScore < 60 {
            return SessionAdaptation(
                mode: .normal,
                weightReduction: 0.15,
                repAdjustment: 0,
                tempoAdjustment: "3-1-2",
                whyMessage: "Recovery below average (\(Int(readinessScore))%). Reducing loads by 15% to maintain quality."
            )
        }

        // Cycle phase adaptation (luteal → reduce intensity)
        if let phase = cyclePhase, phase == .luteal {
            return SessionAdaptation(
                mode: .normal,
                weightReduction: 0.10,
                repAdjustment: 1,
                tempoAdjustment: "3-1-2",
                whyMessage: "Luteal phase detected — slight load reduction, +1 rep for comfort and recovery."
            )
        }

        return nil
    }

    // MARK: - Recalculate Reps

    /// Adjusts weight and reps when swapping exercises.
    func recalculateReps(
        original: Exercise,
        new: Exercise,
        weight: Double,
        reps: Int,
        targetRPE: Double
    ) -> (Double, String) {
        let origEquip = original.equipmentType ?? ""
        let newEquip = new.equipmentType ?? ""

        var weightMultiplier: Double = 1.0

        // Equipment-based adjustments
        if origEquip == "barbell" && newEquip == "dumbbell" {
            weightMultiplier = 0.40 // Each DB ~40% of barbell
        } else if origEquip == "dumbbell" && newEquip == "barbell" {
            weightMultiplier = 2.2
        } else if origEquip == "barbell" && (newEquip == "machine" || newEquip == "cable") {
            weightMultiplier = 0.70
        } else if (origEquip == "machine" || origEquip == "cable") && newEquip == "barbell" {
            weightMultiplier = 1.3
        }

        let newWeight = round(weight * weightMultiplier / 2.5) * 2.5
        let repAdjust = newEquip == "machine" ? 2 : 0 // Machines allow slightly higher reps
        let newReps = "\(reps)-\(reps + 2 + repAdjust)"

        return (newWeight, newReps)
    }

    // MARK: - Helpers

    private func evaluateMorphoFit(
        _ exercise: Exercise,
        measurements: SegmentMeasurements?
    ) -> ExerciseSwapSuggestion.MorphoFit {
        guard let measures = measurements else { return .good }

        let risk = exercise.riskLevel ?? "optimal"
        if risk == "optimal" { return .ideal }
        if risk == "caution" { return .good }

        // If we have morpho data and exercise risk is high, downgrade
        if measures.femurToTorsoRatio > 0.55 {
            let name = exercise.name.lowercased()
            if name.contains("squat") { return .acceptable }
        }

        return .good
    }

    private func generateSwapReason(
        original: Exercise,
        replacement: Exercise,
        morphoFit: ExerciseSwapSuggestion.MorphoFit
    ) -> String {
        var reasons: [String] = []

        if replacement.stretchPositionBonus {
            reasons.append("stretch-position for extra growth stimulus")
        }

        if replacement.equipmentType != original.equipmentType {
            reasons.append("different equipment for varied stimulus")
        }

        if morphoFit == .ideal {
            reasons.append("great fit for your body proportions")
        }

        if replacement.riskLevel == "optimal" {
            reasons.append("low injury risk")
        }

        let reasonStr = reasons.isEmpty ? "Similar muscle activation" : reasons.joined(separator: ", ").capitalized
        return reasonStr + "."
    }
}
