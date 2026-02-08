import Foundation
import CoreData

// MARK: - OverloadDecision

/// Result of the overload analysis for a single exercise.
struct OverloadDecision: Identifiable {
    let id = UUID()
    let exerciseName: String
    let previousWeight: Double
    let newWeight: Double
    let weightChange: Double
    let whyMessage: String
    let confidenceLevel: ConfidenceLevel

    enum ConfidenceLevel: String {
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var badgeColor: String {
            switch self {
            case .high: return "neonGreen"
            case .medium: return "cyberOrange"
            case .low: return "neonRed"
            }
        }
    }

    var isIncrease: Bool { weightChange > 0 }
    var isDecrease: Bool { weightChange < 0 }
    var isMaintain: Bool { weightChange == 0 }
}

// MARK: - OverloadManager

/// Analyzes VBT data post-week to calculate progressive overload for next week.
final class OverloadManager {

    // MARK: - Process Week End

    /// Analyzes completed week and generates overload decisions for next week.
    func processWeekEnd(
        completedWeek: ProgramWeek,
        nextWeek: ProgramWeek,
        context: NSManagedObjectContext
    ) -> [OverloadDecision] {
        var decisions: [OverloadDecision] = []

        let completedExercises = completedWeek.trainingDays.flatMap(\.sortedExercises)
        let nextExercises = nextWeek.trainingDays.flatMap(\.sortedExercises)

        for nextEx in nextExercises {
            guard let exercise = nextEx.exercise else { continue }

            // Find matching completed exercise
            let matchingCompleted = completedExercises.first { $0.exercise?.id == exercise.id }
            let currentWeight = matchingCompleted?.targetWeightKg ?? nextEx.targetWeightKg

            // Fetch recent sets for this exercise
            let recentSets = fetchRecentSets(
                exerciseName: exercise.name,
                weekCount: 2,
                context: context
            )

            let decision = calculateOverload(
                exerciseName: exercise.name,
                currentWeight: currentWeight,
                recentSets: recentSets,
                targetRPE: nextEx.targetRPE,
                targetVelocityZone: nextEx.parsedVelocityZone ?? .strength
            )

            // Apply decision to next week's exercise
            nextEx.targetWeightKg = decision.newWeight

            decisions.append(decision)
        }

        // Save updated weights
        do {
            try context.save()
        } catch {
            context.rollback()
        }

        return decisions
    }

    // MARK: - Calculate Overload

    /// Determines weight adjustment based on velocity and RPE data.
    func calculateOverload(
        exerciseName: String,
        currentWeight: Double,
        recentSets: [WorkoutSet],
        targetRPE: Double,
        targetVelocityZone: VelocityZone
    ) -> OverloadDecision {
        guard !recentSets.isEmpty else {
            return OverloadDecision(
                exerciseName: exerciseName,
                previousWeight: currentWeight,
                newWeight: currentWeight,
                weightChange: 0,
                whyMessage: "No data yet — keeping current weight.",
                confidenceLevel: .low
            )
        }

        // Calculate averages from recent sets
        let avgVelocity = recentSets.map(\.averageConcentricVelocity).reduce(0, +) / Double(recentSets.count)
        let avgRPE = recentSets.map(\.rpe).reduce(0, +) / Double(recentSets.count)
        let avgVelLoss = recentSets.map(\.velocityLossPercent).reduce(0, +) / Double(recentSets.count)

        // Decision logic based on velocity zones and RPE
        let (change, message, confidence) = decideWeightChange(
            avgVelocity: avgVelocity,
            avgRPE: avgRPE,
            avgVelLoss: avgVelLoss,
            targetRPE: targetRPE,
            currentWeight: currentWeight
        )

        let newWeight = max(0, currentWeight + change)

        return OverloadDecision(
            exerciseName: exerciseName,
            previousWeight: currentWeight,
            newWeight: newWeight,
            weightChange: change,
            whyMessage: message,
            confidenceLevel: confidence
        )
    }

    // MARK: - Starting Weight Estimate

    /// Estimates a reasonable starting weight for an exercise based on body metrics.
    func estimateStartingWeight(
        exerciseName: String,
        bodyweight: Double,
        sex: String,
        targetRPE: Double,
        context: NSManagedObjectContext
    ) -> Double {
        // Check historical data first
        let recentSets = fetchRecentSets(exerciseName: exerciseName, weekCount: 4, context: context)
        if let lastSet = recentSets.first {
            // Use last known weight, adjusted for target RPE
            let rpeAdjustment = max(0.7, 1.0 - (targetRPE - lastSet.rpe) * 0.025)
            return round(lastSet.weightKg * rpeAdjustment / 2.5) * 2.5
        }

        // Fallback: estimate from bodyweight ratios
        let ratio = startingWeightRatio(for: exerciseName, sex: sex)
        let estimated = bodyweight * ratio

        // Round to nearest 2.5 kg
        return round(estimated / 2.5) * 2.5
    }

    // MARK: - Fetch Recent Sets

    func fetchRecentSets(
        exerciseName: String,
        weekCount: Int,
        context: NSManagedObjectContext
    ) -> [WorkoutSet] {
        let request = NSFetchRequest<WorkoutSet>(entityName: "WorkoutSet")
        let weeksAgo = Calendar.current.date(byAdding: .weekOfYear, value: -weekCount, to: Date()) ?? Date()
        request.predicate = NSPredicate(
            format: "exercise.name ==[c] %@ AND timestamp >= %@",
            exerciseName, weeksAgo as NSDate
        )
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.fetchLimit = 20

        return (try? context.fetch(request)) ?? []
    }

    // MARK: - Decision Logic

    private func decideWeightChange(
        avgVelocity: Double,
        avgRPE: Double,
        avgVelLoss: Double,
        targetRPE: Double,
        currentWeight: Double
    ) -> (Double, String, OverloadDecision.ConfidenceLevel) {
        // Hypertrophy sweet spot: 0.5-0.75 m/s
        let inHypertrophyZone = avgVelocity >= 0.5 && avgVelocity <= 0.75

        if inHypertrophyZone && avgRPE < 8.0 {
            // Room for progression
            return (2.5, "Good velocity + low RPE — room for progression.", .high)
        }

        if inHypertrophyZone && avgRPE >= 8.0 && avgRPE <= 9.0 {
            // Right on target
            return (0, "Right on target — maintaining current load.", .high)
        }

        if avgVelocity < 0.5 && avgRPE >= 9.0 {
            // Too heavy
            return (-2.5, "Too heavy — reducing to maintain movement quality.", .high)
        }

        if avgVelocity > 0.75 {
            // Too light for hypertrophy
            return (5.0, "Too light for hypertrophy zone — increasing load.", .medium)
        }

        // Fatigue check
        if avgVelLoss > 0.20 {
            return (-2.5, "High fatigue detected — reducing to aid recovery.", .medium)
        }

        // Default: small increase if RPE allows
        if avgRPE < targetRPE {
            return (2.5, "Below target RPE — small increase.", .medium)
        }

        return (0, "Maintaining current load based on available data.", .low)
    }

    // MARK: - Starting Weight Ratios

    private func startingWeightRatio(for exerciseName: String, sex: String) -> Double {
        let isFemale = sex.lowercased() == "female"
        let name = exerciseName.lowercased()
        let modifier = isFemale ? 0.6 : 1.0

        if name.contains("bench") { return 0.5 * modifier }
        if name.contains("squat") { return 0.7 * modifier }
        if name.contains("deadlift") || name.contains("rdl") { return 0.8 * modifier }
        if name.contains("overhead") || name.contains("ohp") { return 0.35 * modifier }
        if name.contains("row") { return 0.45 * modifier }
        if name.contains("hip thrust") { return 0.8 * modifier }
        if name.contains("lat pulldown") { return 0.4 * modifier }
        if name.contains("curl") { return 0.15 * modifier }
        if name.contains("lateral raise") { return 0.05 * modifier }

        return 0.3 * modifier
    }
}
