import Foundation
import CoreData

/// Per-muscle recovery status for heatmap rendering.
struct MuscleRecoveryStatus {
    let muscleName: String
    let bodyRegion: String
    let recoveryPercent: Double  // 0.0 (fully fatigued) to 100.0 (fully recovered)
    let hoursSinceTraining: Double
    let weeklyVolumeSets: Int
    let estimatedFullRecoveryHours: Double

    /// Color zone for heatmap rendering.
    var zone: RecoveryZone {
        if recoveryPercent >= 90 { return .fullyRecovered }
        if recoveryPercent >= 70 { return .recovered }
        if recoveryPercent >= 50 { return .moderate }
        if recoveryPercent >= 30 { return .fatigued }
        return .overreached
    }
}

/// Recovery color zones for heatmap display.
enum RecoveryZone: String {
    case fullyRecovered  // Green — ready for max effort
    case recovered       // Light green — good to train
    case moderate        // Yellow — can train, reduced volume
    case fatigued        // Orange — rest recommended
    case overreached     // Red — do not train

    var displayName: String {
        switch self {
        case .fullyRecovered: return "Fully Recovered"
        case .recovered:      return "Recovered"
        case .moderate:       return "Moderate"
        case .fatigued:       return "Fatigued"
        case .overreached:    return "Overreached"
        }
    }
}

/// Generates muscle recovery heatmap data based on training volume and elapsed time.
/// Uses a science-based recovery model: ~48h baseline recovery, extended by volume and RPE.
final class RecoveryHeatmapEngine: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Recovery Model Constants

    /// Base recovery time in hours for a single moderate set.
    private let baseRecoveryHours: Double = 48.0

    /// Additional recovery hours per set beyond the first.
    private let hoursPerAdditionalSet: Double = 4.0

    /// RPE multiplier: high RPE (9-10) adds 20-40% recovery time.
    private let highRPEMultiplier: Double = 1.3

    /// Recovery rate varies by muscle size.
    private static let muscleRecoveryRates: [String: Double] = [
        // Large muscles recover slower (multiplier > 1.0)
        "Quadriceps": 1.3,
        "Hamstrings": 1.2,
        "Glute Max": 1.3,
        "Upper Lats": 1.2,
        "Lower Lats": 1.2,
        "Erector Spinae": 1.4,
        // Medium muscles — baseline
        "Upper Chest": 1.0,
        "Lower Chest": 1.0,
        "Front Delts": 1.0,
        "Side Delts": 0.9,
        "Rear Delts": 0.9,
        "Glute Med": 1.0,
        "Adductors": 1.1,
        "Upper Traps": 1.0,
        "Mid Traps": 1.0,
        "Rhomboids": 1.0,
        "Abs": 0.8,
        "Obliques": 0.8,
        // Small muscles recover faster (multiplier < 1.0)
        "Biceps (Long Head)": 0.7,
        "Biceps (Short Head)": 0.7,
        "Triceps (Long Head)": 0.8,
        "Triceps (Lateral)": 0.8,
        "Forearms": 0.7,
        "Calves": 0.8,
    ]

    /// Maps exercise primaryMuscle strings to MuscleGroup names.
    private static let muscleMapping: [String: [String]] = [
        "Quadriceps": ["Quadriceps"],
        "Hamstrings": ["Hamstrings"],
        "Glutes": ["Glute Max", "Glute Med"],
        "Chest": ["Upper Chest", "Lower Chest"],
        "Back": ["Upper Lats", "Lower Lats"],
        "Lats": ["Upper Lats", "Lower Lats"],
        "Shoulders": ["Front Delts", "Side Delts"],
        "Front Delts": ["Front Delts"],
        "Side Delts": ["Side Delts"],
        "Rear Delts": ["Rear Delts"],
        "Traps": ["Upper Traps", "Mid Traps"],
        "Biceps": ["Biceps (Long Head)", "Biceps (Short Head)"],
        "Triceps": ["Triceps (Long Head)", "Triceps (Lateral)"],
        "Forearms": ["Forearms"],
        "Calves": ["Calves"],
        "Core": ["Abs", "Obliques"],
        "Abs": ["Abs"],
        "Lower Back": ["Erector Spinae"],
        "Erector Spinae": ["Erector Spinae"],
        "Adductors": ["Adductors"],
    ]

    // MARK: - Generate Heatmap

    /// Computes recovery status for all muscle groups from CoreData.
    func generateHeatmap(context: NSManagedObjectContext) -> [MuscleRecoveryStatus] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MuscleGroup")
        guard let groups = try? context.fetch(request) else { return [] }

        let now = Date()
        return groups.compactMap { group -> MuscleRecoveryStatus? in
            guard let name = group.value(forKey: "name") as? String else { return nil }
            let region = (group.value(forKey: "bodyRegion") as? String) ?? "upper"
            let volumeSets = Int((group.value(forKey: "weeklyVolumeSets") as? Int16) ?? 0)
            let lastTrained = group.value(forKey: "lastTrainedDate") as? Date
            let storedScore = (group.value(forKey: "currentRecoveryScore") as? Double) ?? 100.0

            let hoursSince: Double
            let recoveryPercent: Double

            if let lastTrained = lastTrained {
                hoursSince = now.timeIntervalSince(lastTrained) / 3600.0
                recoveryPercent = computeRecovery(
                    hoursSinceTraining: hoursSince,
                    volumeSets: volumeSets,
                    muscleName: name
                )
            } else {
                hoursSince = 999
                recoveryPercent = storedScore
            }

            let estimatedFull = estimateFullRecoveryHours(
                volumeSets: volumeSets,
                muscleName: name
            )

            return MuscleRecoveryStatus(
                muscleName: name,
                bodyRegion: region,
                recoveryPercent: recoveryPercent,
                hoursSinceTraining: hoursSince,
                weeklyVolumeSets: volumeSets,
                estimatedFullRecoveryHours: estimatedFull
            )
        }
    }

    /// Returns recovery scores as a simple dictionary (muscle name → percentage).
    func generateHeatmapScores(context: NSManagedObjectContext) -> [String: Double] {
        let statuses = generateHeatmap(context: context)
        var scores: [String: Double] = [:]
        for status in statuses {
            scores[status.muscleName] = status.recoveryPercent
        }
        return scores
    }

    // MARK: - Log Training Volume

    /// Records training stimulus for muscles involved in a workout.
    /// Called after each set completion to update fatigue tracking.
    func logVolume(
        exerciseName: String,
        primaryMuscle: String?,
        secondaryMuscles: String?,
        sets: Int,
        rpe: Double,
        context: NSManagedObjectContext
    ) {
        let affectedMuscles = resolveAffectedMuscles(
            primary: primaryMuscle,
            secondary: secondaryMuscles
        )

        let request = NSFetchRequest<NSManagedObject>(entityName: "MuscleGroup")
        guard let groups = try? context.fetch(request) else { return }

        let now = Date()
        let groupsByName = Dictionary(grouping: groups) {
            ($0.value(forKey: "name") as? String) ?? ""
        }

        for (muscle, isPrimary) in affectedMuscles {
            guard let group = groupsByName[muscle]?.first else { continue }

            // Primary muscles get full volume credit, secondary get 50%
            let effectiveSets = isPrimary ? sets : max(1, sets / 2)
            let currentVolume = Int((group.value(forKey: "weeklyVolumeSets") as? Int16) ?? 0)
            let newVolume = Int16(currentVolume + effectiveSets)

            group.setValue(newVolume, forKey: "weeklyVolumeSets")
            group.setValue(now, forKey: "lastTrainedDate")

            // Compute immediate recovery impact
            let recoveryScore = computeRecovery(
                hoursSinceTraining: 0,
                volumeSets: Int(newVolume),
                muscleName: muscle
            )
            group.setValue(recoveryScore, forKey: "currentRecoveryScore")
        }

        try? context.save()
    }

    /// Resets weekly volume counters (call at start of each week).
    func resetWeeklyVolume(context: NSManagedObjectContext) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MuscleGroup")
        guard let groups = try? context.fetch(request) else { return }

        for group in groups {
            group.setValue(Int16(0), forKey: "weeklyVolumeSets")
        }

        try? context.save()
    }

    // MARK: - Recovery Computation

    /// Computes recovery percentage based on time elapsed and training volume.
    /// Model: Exponential recovery curve scaled by volume and muscle size.
    ///
    /// - Recovery follows: `recovery = 100 × (1 - e^(-t / τ))` where τ is the time constant
    /// - τ = baseRecovery × muscleRateModifier × volumeScaling
    private func computeRecovery(
        hoursSinceTraining: Double,
        volumeSets: Int,
        muscleName: String
    ) -> Double {
        guard volumeSets > 0 else { return 100.0 }

        let muscleRate = Self.muscleRecoveryRates[muscleName] ?? 1.0

        // Volume scaling: more sets = longer recovery (diminishing returns)
        let volumeScale = 1.0 + (Double(max(0, volumeSets - 1)) * 0.15)

        // Time constant (hours to ~63% recovery)
        let tau = baseRecoveryHours * muscleRate * volumeScale

        // Exponential recovery curve
        let recovery = 100.0 * (1.0 - exp(-hoursSinceTraining / tau))

        return min(100.0, max(0.0, recovery))
    }

    /// Estimates total hours for full (95%) recovery.
    private func estimateFullRecoveryHours(volumeSets: Int, muscleName: String) -> Double {
        guard volumeSets > 0 else { return 0 }
        let muscleRate = Self.muscleRecoveryRates[muscleName] ?? 1.0
        let volumeScale = 1.0 + (Double(max(0, volumeSets - 1)) * 0.15)
        let tau = baseRecoveryHours * muscleRate * volumeScale
        // 95% recovery ≈ 3τ
        return tau * 3.0
    }

    // MARK: - Muscle Resolution

    /// Resolves exercise muscle names to MuscleGroup entity names.
    /// Returns tuples of (muscleName, isPrimary).
    private func resolveAffectedMuscles(
        primary: String?,
        secondary: String?
    ) -> [(String, Bool)] {
        var result: [(String, Bool)] = []

        if let primary = primary {
            let muscles = Self.muscleMapping[primary] ?? [primary]
            for m in muscles {
                result.append((m, true))
            }
        }

        if let secondary = secondary {
            let parts = secondary.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            for part in parts {
                let muscles = Self.muscleMapping[part] ?? [part]
                for m in muscles {
                    if !result.contains(where: { $0.0 == m }) {
                        result.append((m, false))
                    }
                }
            }
        }

        return result
    }
}
