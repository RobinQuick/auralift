import Foundation

// MARK: - LPResult

/// Detailed breakdown of LP earned for a single set.
struct LPResult {
    let baseLP: Double
    let velocityModifier: Double      // 1.0 or 1.1
    let formModifier: Double          // 1.0 or 1.2
    let genderMultiplier: Double      // 1.0 or 1.25
    let totalLP: Int32
}

// MARK: - WorkoutLPResult

/// LP earned for an entire workout, with promotion series status.
struct WorkoutLPResult {
    let totalLP: Int32
    let setResults: [LPResult]
    let promotionStatus: PromotionStatus
}

// MARK: - PromotionStatus

/// Tracks progress through the promotion series required to advance tiers.
struct PromotionStatus {
    let isInSeries: Bool
    let seriesWins: Int              // 0 to 3
    let seriesScores: [Double]       // workout scores in current series
    let isPromoted: Bool             // true if just promoted this workout
    let newTier: RankTier?           // tier promoted to (nil if not promoted)
}

// MARK: - ExerciseStrengthLevel

/// What tier a specific lift corresponds to based on bodyweight ratio standards.
struct ExerciseStrengthLevel {
    let exerciseName: String
    let weightLifted: Double
    let bodyweight: Double
    let ratio: Double
    let tier: RankTier
}

// MARK: - StrengthStandards

/// Science-based bodyweight ratio thresholds per exercise per tier.
/// Sources: NSCA strength standards, Stronger by Science databases.
enum StrengthStandards {

    /// Bodyweight ratio required to reach each tier for each exercise.
    /// Key = exercise name matching FormAnalyzer/VBTService exercise names.
    static let ratios: [String: [RankTier: Double]] = [
        // User-specified big 3 standards
        "Barbell Bench Press": [
            .iron: 0.30, .bronze: 0.50, .silver: 0.75, .gold: 1.00,
            .platinum: 1.30, .diamond: 1.60, .master: 1.80,
            .grandmaster: 2.00, .challenger: 2.20
        ],
        "Barbell Back Squat": [
            .iron: 0.50, .bronze: 0.70, .silver: 0.95, .gold: 1.20,
            .platinum: 1.70, .diamond: 2.10, .master: 2.30,
            .grandmaster: 2.50, .challenger: 2.70
        ],
        "Conventional Deadlift": [
            .iron: 0.70, .bronze: 1.00, .silver: 1.25, .gold: 1.50,
            .platinum: 2.00, .diamond: 2.50, .master: 2.70,
            .grandmaster: 3.00, .challenger: 3.20
        ],
        // Derived standards for remaining exercises
        "Overhead Press": [
            .iron: 0.20, .bronze: 0.35, .silver: 0.50, .gold: 0.65,
            .platinum: 0.85, .diamond: 1.00, .master: 1.10,
            .grandmaster: 1.20, .challenger: 1.35
        ],
        "Barbell Row": [
            .iron: 0.30, .bronze: 0.45, .silver: 0.65, .gold: 0.85,
            .platinum: 1.10, .diamond: 1.35, .master: 1.50,
            .grandmaster: 1.65, .challenger: 1.80
        ],
        "Romanian Deadlift": [
            .iron: 0.40, .bronze: 0.60, .silver: 0.80, .gold: 1.00,
            .platinum: 1.30, .diamond: 1.60, .master: 1.80,
            .grandmaster: 2.00, .challenger: 2.20
        ],
        "Pull-Up": [
            .iron: 0.50, .bronze: 0.80, .silver: 1.00, .gold: 1.20,
            .platinum: 1.50, .diamond: 1.80, .master: 2.00,
            .grandmaster: 2.20, .challenger: 2.50
        ],
        "Lat Pulldown": [
            .iron: 0.30, .bronze: 0.50, .silver: 0.65, .gold: 0.80,
            .platinum: 1.00, .diamond: 1.20, .master: 1.35,
            .grandmaster: 1.50, .challenger: 1.65
        ],
        "Hip Thrust": [
            .iron: 0.50, .bronze: 0.80, .silver: 1.10, .gold: 1.50,
            .platinum: 2.00, .diamond: 2.50, .master: 2.80,
            .grandmaster: 3.00, .challenger: 3.30
        ],
    ]

    /// Returns the tier achieved for a given exercise at a given bodyweight ratio.
    static func tierForLift(exerciseName: String, ratio: Double) -> RankTier {
        guard let exerciseRatios = ratios[exerciseName] else { return .iron }

        var achievedTier: RankTier = .iron
        for tier in RankTier.allCases {
            guard let threshold = exerciseRatios[tier] else { continue }
            if ratio >= threshold {
                achievedTier = tier
            } else {
                break
            }
        }
        return achievedTier
    }

    /// Returns the bodyweight ratio threshold for a specific exercise and tier.
    static func threshold(exercise: String, tier: RankTier) -> Double? {
        ratios[exercise]?[tier]
    }
}

// MARK: - RankingEngine

/// Calculates Lift Points (LP) and assigns competitive tier rankings.
///
/// LP formula: `Score = (Weight / Bodyweight) × Reps × VelocityModifier × FormModifier × GenderMultiplier`
///
/// - Velocity modifier: +10% LP when mean concentric velocity is in the optimal
///   hypertrophy zone (0.4–0.6 m/s)
/// - Form modifier: +20% LP when form score ≥ 95 (perfect form, no deviations)
/// - Gender adjustment: Women receive a 1.25× multiplier (equivalent to -20% thresholds)
/// - Promotion series: Advancing a tier requires 3 consecutive workouts with increasing scores
final class RankingEngine: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Promotion Series State

    private(set) var promotionSeriesScores: [Double] = []
    private let promotionWinsRequired = 3

    // MARK: - Velocity Zone Constants

    /// Optimal hypertrophy velocity range (m/s) for LP bonus.
    private let optimalVelocityMin = 0.4
    private let optimalVelocityMax = 0.6

    /// Form score threshold for perfect form LP bonus (0-100 scale).
    private let perfectFormThreshold = 95.0

    // MARK: - Set LP Calculation

    /// Calculates LP earned for a single set.
    ///
    /// - Parameters:
    ///   - weight: Weight lifted in kilograms.
    ///   - reps: Number of repetitions completed.
    ///   - bodyweight: User's bodyweight in kilograms.
    ///   - meanConcentricVelocity: Mean concentric velocity in m/s.
    ///   - formScore: Form quality score (0–100).
    ///   - biologicalSex: User's biological sex ("male" or "female").
    /// - Returns: Detailed LP breakdown for this set.
    func calculateSetLP(
        weight: Double,
        reps: Int,
        bodyweight: Double,
        meanConcentricVelocity: Double,
        formScore: Double,
        biologicalSex: String?
    ) -> LPResult {
        guard bodyweight > 0, weight > 0, reps > 0 else {
            return LPResult(baseLP: 0, velocityModifier: 1.0,
                            formModifier: 1.0, genderMultiplier: 1.0, totalLP: 0)
        }

        // Base LP = strength-to-weight ratio × reps
        let ratio = weight / bodyweight
        let baseLP = ratio * Double(reps)

        // Velocity modifier: optimal hypertrophy zone (0.4–0.6 m/s) = +10%
        let velocityMod: Double
        if meanConcentricVelocity >= optimalVelocityMin
            && meanConcentricVelocity <= optimalVelocityMax {
            velocityMod = 1.1
        } else {
            velocityMod = 1.0
        }

        // Form modifier: perfect form (≥ 95/100) = +20%
        let formMod: Double
        if formScore >= perfectFormThreshold {
            formMod = 1.2
        } else {
            formMod = 1.0
        }

        // Gender adjustment: -20% thresholds for women = ×1.25 score
        let genderMult: Double
        if biologicalSex?.lowercased() == "female" {
            genderMult = 1.25
        } else {
            genderMult = 1.0
        }

        let total = baseLP * velocityMod * formMod * genderMult

        return LPResult(
            baseLP: baseLP,
            velocityModifier: velocityMod,
            formModifier: formMod,
            genderMultiplier: genderMult,
            totalLP: max(1, Int32(total.rounded()))
        )
    }

    // MARK: - Workout LP Calculation

    /// Calculates total LP earned for an entire workout.
    func calculateWorkoutLP(
        sets: [(weight: Double, reps: Int, velocity: Double, formScore: Double)],
        bodyweight: Double,
        biologicalSex: String?
    ) -> (totalLP: Int32, setResults: [LPResult]) {
        var totalLP: Int32 = 0
        var results: [LPResult] = []

        for set in sets {
            let result = calculateSetLP(
                weight: set.weight,
                reps: set.reps,
                bodyweight: bodyweight,
                meanConcentricVelocity: set.velocity,
                formScore: set.formScore,
                biologicalSex: biologicalSex
            )
            totalLP += result.totalLP
            results.append(result)
        }

        return (totalLP, results)
    }

    // MARK: - Tier Determination

    /// Determines the user's competitive tier based on cumulative LP.
    func determineTier(totalLP: Int32) -> RankTier {
        for tier in RankTier.allCases.reversed() {
            if totalLP >= tier.lpThreshold {
                return tier
            }
        }
        return .iron
    }

    // MARK: - Promotion Series

    /// Processes a workout's score through the promotion series.
    ///
    /// To advance a tier, the user must complete 3 consecutive workouts
    /// where each workout's LP score is higher than the previous one.
    /// Failing to increase resets the series.
    ///
    /// - Parameters:
    ///   - workoutLP: LP earned in this workout.
    ///   - currentTier: User's current tier before this workout.
    ///   - cumulativeLP: User's total cumulative LP after adding this workout.
    /// - Returns: Promotion status including whether the user was promoted.
    func processPromotionSeries(
        workoutLP: Int32,
        currentTier: RankTier,
        cumulativeLP: Int32
    ) -> PromotionStatus {
        let workoutScore = Double(workoutLP)

        // Check if cumulative LP has reached next tier threshold
        guard let nextTier = currentTier.nextTier,
              cumulativeLP >= nextTier.lpThreshold else {
            return PromotionStatus(
                isInSeries: false,
                seriesWins: 0,
                seriesScores: promotionSeriesScores,
                isPromoted: false,
                newTier: nil
            )
        }

        // Process promotion series: each workout must score higher than the last
        if let lastScore = promotionSeriesScores.last {
            if workoutScore > lastScore {
                promotionSeriesScores.append(workoutScore)
            } else {
                // Failed to increase — reset series with current score
                promotionSeriesScores = [workoutScore]
            }
        } else {
            promotionSeriesScores = [workoutScore]
        }

        let promoted = promotionSeriesScores.count >= promotionWinsRequired
        let newTier = promoted ? nextTier : nil

        if promoted {
            promotionSeriesScores = []
        }

        return PromotionStatus(
            isInSeries: true,
            seriesWins: min(promotionSeriesScores.count, promotionWinsRequired),
            seriesScores: promotionSeriesScores,
            isPromoted: promoted,
            newTier: newTier
        )
    }

    /// Resets the promotion series (e.g., after tier demotion or manual reset).
    func resetPromotionSeries() {
        promotionSeriesScores = []
    }

    // MARK: - Exercise Strength Level

    /// Returns the strength tier a specific lift corresponds to.
    func exerciseStrengthLevel(
        exerciseName: String,
        weight: Double,
        bodyweight: Double
    ) -> ExerciseStrengthLevel {
        guard bodyweight > 0 else {
            return ExerciseStrengthLevel(
                exerciseName: exerciseName,
                weightLifted: weight,
                bodyweight: bodyweight,
                ratio: 0,
                tier: .iron
            )
        }

        let ratio = weight / bodyweight
        let tier = StrengthStandards.tierForLift(exerciseName: exerciseName, ratio: ratio)

        return ExerciseStrengthLevel(
            exerciseName: exerciseName,
            weightLifted: weight,
            bodyweight: bodyweight,
            ratio: ratio,
            tier: tier
        )
    }

    // MARK: - Aggregate Strength Rating

    /// Computes an overall strength tier across multiple exercises.
    /// Uses the median tier as the representative level.
    func overallStrengthTier(
        lifts: [(exerciseName: String, weight: Double)],
        bodyweight: Double
    ) -> RankTier {
        guard bodyweight > 0, !lifts.isEmpty else { return .iron }

        let tiers = lifts.map { lift in
            StrengthStandards.tierForLift(
                exerciseName: lift.exerciseName,
                ratio: lift.weight / bodyweight
            )
        }

        let allCases = RankTier.allCases
        let indices = tiers.compactMap { tier in allCases.firstIndex(of: tier) }
        guard !indices.isEmpty else { return .iron }

        let sorted = indices.sorted()
        let medianIndex = sorted[sorted.count / 2]
        return allCases[medianIndex]
    }
}
