import Foundation
import CoreData

/// Readiness assessment result with component scores.
struct ReadinessAssessment {
    let overallScore: Double        // 0.0 to 100.0
    let hrvScore: Double            // 0.0 to 100.0
    let sleepScore: Double          // 0.0 to 100.0
    let restingHRScore: Double      // 0.0 to 100.0
    let muscleRecoveryScore: Double // 0.0 to 100.0
    let adjustment: TrainingAdjustment

    var readinessLevel: ReadinessLevel {
        if overallScore >= 85 { return .optimal }
        if overallScore >= 70 { return .good }
        if overallScore >= 50 { return .moderate }
        if overallScore >= 30 { return .low }
        return .critical
    }
}

/// Readiness classification.
enum ReadinessLevel: String {
    case optimal   // Green — push hard
    case good      // Light green — normal training
    case moderate  // Yellow — reduced intensity
    case low       // Orange — light session or rest
    case critical  // Red — mandatory rest/deload

    var displayName: String {
        rawValue.capitalized
    }
}

/// Auto-deload recommendation with reason.
struct DeloadRecommendation {
    let shouldDeload: Bool
    let reason: DeloadReason?
    let suggestedLoadReduction: Double  // 0.0 to 1.0 (e.g., 0.20 = -20%)
    let durationDays: Int               // Suggested deload period

    static let none = DeloadRecommendation(
        shouldDeload: false,
        reason: nil,
        suggestedLoadReduction: 0,
        durationDays: 0
    )
}

/// Reason for auto-deload trigger.
enum DeloadReason: String {
    case hrvDrop = "HRV dropped >15% below baseline"
    case velocityDecline = "Bar velocity declining for 2+ sessions"
    case poorSleep = "Chronic sleep deficit detected"
    case combinedFatigue = "Multiple fatigue markers elevated"

    var displayDescription: String { rawValue }
}

/// Integrates HealthKit biometrics with recovery data to adapt training loads.
/// Computes readiness scores and triggers auto-deload when fatigue markers accumulate.
final class BioAdaptiveService: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Readiness Weights

    /// Component weights for readiness score (must sum to 1.0).
    private let hrvWeight: Double = 0.35
    private let sleepWeight: Double = 0.30
    private let restingHRWeight: Double = 0.15
    private let muscleRecoveryWeight: Double = 0.20

    // MARK: - Thresholds

    /// HRV drop percentage that triggers deload.
    private let hrvDeloadThreshold: Double = 0.15

    /// Consecutive sessions of velocity decline for deload trigger.
    private let velocityDeclineSessions: Int = 2

    /// Sleep hours threshold for chronic deficit warning.
    private let sleepDeficitThreshold: Double = 6.0

    // MARK: - Readiness Calculation

    /// Calculates comprehensive readiness score from health and training data.
    func calculateReadiness(
        snapshot: HealthSnapshot,
        hrvBaseline: Double,
        muscleRecoveryAverage: Double,
        cyclePhase: CyclePhase?
    ) -> ReadinessAssessment {

        let hrvScore = computeHRVScore(current: snapshot.hrv, baseline: hrvBaseline)
        let sleepScore = computeSleepScore(hours: snapshot.sleepHours)
        let restingHRScore = computeRestingHRScore(bpm: snapshot.restingHR)
        let muscleScore = muscleRecoveryAverage

        var overall = hrvScore * hrvWeight
            + sleepScore * sleepWeight
            + restingHRScore * restingHRWeight
            + muscleScore * muscleRecoveryWeight

        // Apply cycle phase modifier if available
        if let phase = cyclePhase {
            overall *= phase.intensityModifier
            overall = min(100, overall)
        }

        let adjustment = computeTrainingAdjustment(readiness: overall, cyclePhase: cyclePhase)

        return ReadinessAssessment(
            overallScore: overall,
            hrvScore: hrvScore,
            sleepScore: sleepScore,
            restingHRScore: restingHRScore,
            muscleRecoveryScore: muscleScore,
            adjustment: adjustment
        )
    }

    // MARK: - Auto-Deload Detection

    /// Evaluates whether auto-deload should be triggered.
    func evaluateDeload(
        snapshot: HealthSnapshot,
        hrvBaseline: Double,
        recentSessionVelocities: [Double],
        recentSleepHours: [Double]
    ) -> DeloadRecommendation {

        var reasons: [DeloadReason] = []

        // Check 1: HRV drop >15% below baseline
        if hrvBaseline > 0 && snapshot.hrv > 0 {
            let hrvDrop = (hrvBaseline - snapshot.hrv) / hrvBaseline
            if hrvDrop > hrvDeloadThreshold {
                reasons.append(.hrvDrop)
            }
        }

        // Check 2: Velocity declining for 2+ consecutive sessions
        if recentSessionVelocities.count >= velocityDeclineSessions + 1 {
            let recent = Array(recentSessionVelocities.suffix(velocityDeclineSessions + 1))
            var consecutiveDeclines = 0
            for i in 1..<recent.count {
                if recent[i] < recent[i - 1] {
                    consecutiveDeclines += 1
                } else {
                    consecutiveDeclines = 0
                }
            }
            if consecutiveDeclines >= velocityDeclineSessions {
                reasons.append(.velocityDecline)
            }
        }

        // Check 3: Chronic sleep deficit (3+ days below threshold)
        if recentSleepHours.count >= 3 {
            let recentThree = Array(recentSleepHours.suffix(3))
            let allDeficit = recentThree.allSatisfy { $0 < sleepDeficitThreshold }
            if allDeficit {
                reasons.append(.poorSleep)
            }
        }

        guard !reasons.isEmpty else { return .none }

        // Combined fatigue: multiple signals firing
        let primaryReason: DeloadReason
        let loadReduction: Double
        let duration: Int

        if reasons.count >= 2 {
            primaryReason = .combinedFatigue
            loadReduction = 0.25  // -25% for multiple markers
            duration = 5          // 5-day deload
        } else {
            primaryReason = reasons[0]
            loadReduction = 0.20  // -20% standard deload
            duration = 3          // 3-day deload
        }

        return DeloadRecommendation(
            shouldDeload: true,
            reason: primaryReason,
            suggestedLoadReduction: loadReduction,
            durationDays: duration
        )
    }

    // MARK: - Training Adjustment

    /// Computes volume and intensity modifiers based on readiness.
    func computeTrainingAdjustment(readiness: Double, cyclePhase: CyclePhase?) -> TrainingAdjustment {
        let volumeMod: Double
        let intensityMod: Double
        let recommendation: String
        let shouldDeload: Bool

        switch readiness {
        case 85...100:
            volumeMod = 1.1
            intensityMod = 1.05
            recommendation = "Readiness is high. Push for PRs and add volume."
            shouldDeload = false

        case 70..<85:
            volumeMod = 1.0
            intensityMod = 1.0
            recommendation = "Good readiness. Follow your normal program."
            shouldDeload = false

        case 50..<70:
            volumeMod = 0.85
            intensityMod = 0.90
            recommendation = "Moderate fatigue detected. Reduce volume by 15% and intensity by 10%."
            shouldDeload = false

        case 30..<50:
            volumeMod = 0.70
            intensityMod = 0.80
            recommendation = "Low readiness. Consider a light session focused on technique and mobility."
            shouldDeload = false

        default:
            volumeMod = 0.50
            intensityMod = 0.70
            recommendation = "Critical fatigue. Rest day strongly recommended. Auto-deload activated."
            shouldDeload = true
        }

        // Apply cycle phase modifiers on top
        let finalVolume: Double
        let finalIntensity: Double
        if let phase = cyclePhase {
            finalVolume = volumeMod * phase.volumeModifier
            finalIntensity = intensityMod * phase.intensityModifier
        } else {
            finalVolume = volumeMod
            finalIntensity = intensityMod
        }

        return TrainingAdjustment(
            volumeModifier: min(1.2, finalVolume),
            intensityModifier: min(1.1, finalIntensity),
            recommendation: recommendation,
            shouldDeload: shouldDeload
        )
    }

    // MARK: - Save Recovery Snapshot

    /// Saves a readiness assessment to CoreData for historical tracking.
    func saveSnapshot(
        assessment: ReadinessAssessment,
        snapshot: HealthSnapshot,
        cyclePhase: CyclePhase?,
        context: NSManagedObjectContext
    ) {
        let record = NSEntityDescription.insertNewObject(forEntityName: "RecoverySnapshot", into: context)
        record.setValue(UUID(), forKey: "id")
        record.setValue(Date(), forKey: "snapshotDate")
        record.setValue(snapshot.hrv, forKey: "hrvValue")
        record.setValue(snapshot.sleepHours, forKey: "sleepHours")
        record.setValue(assessment.sleepScore, forKey: "sleepQualityScore")
        record.setValue(snapshot.restingHR, forKey: "restingHeartRate")
        record.setValue(snapshot.activeEnergy, forKey: "activeEnergyBurned")
        record.setValue(cyclePhase?.rawValue, forKey: "cyclePhase")
        record.setValue(assessment.overallScore, forKey: "overallReadiness")

        try? context.save()
    }

    // MARK: - Fetch Velocity Trend

    /// Fetches peak velocities from recent workout sessions for decline detection.
    func fetchRecentSessionVelocities(
        count: Int = 5,
        context: NSManagedObjectContext
    ) -> [Double] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "WorkoutSession")
        request.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: false)]
        request.fetchLimit = count

        guard let sessions = try? context.fetch(request) else { return [] }

        return sessions.reversed().compactMap { session in
            let velocity = (session.value(forKey: "peakVelocity") as? Double) ?? 0
            return velocity > 0 ? velocity : nil
        }
    }

    // MARK: - HRV Baseline

    /// Computes 14-day HRV baseline from readings.
    func computeHRVBaseline(from readings: [HRVReading]) -> Double {
        guard !readings.isEmpty else { return 0 }
        let sum = readings.map(\.value).reduce(0, +)
        return sum / Double(readings.count)
    }

    // MARK: - Component Scoring

    /// Scores HRV relative to personal baseline.
    /// Above baseline = 80-100, at baseline = 70-80, below = scaled down.
    private func computeHRVScore(current: Double, baseline: Double) -> Double {
        guard baseline > 0 else {
            // No baseline — use population norms (healthy adult: 40-60ms SDNN)
            if current >= 60 { return 90 }
            if current >= 40 { return 70 }
            if current >= 25 { return 50 }
            return max(20, current)
        }

        let ratio = current / baseline

        if ratio >= 1.1 {
            // Above baseline — excellent
            return min(100, 85 + (ratio - 1.1) * 50)
        } else if ratio >= 0.95 {
            // Near baseline — good
            return 70 + (ratio - 0.95) * 100
        } else if ratio >= 0.85 {
            // Slightly below — moderate
            return 50 + (ratio - 0.85) * 200
        } else {
            // Significantly below — poor
            return max(10, 50 * ratio / 0.85)
        }
    }

    /// Scores sleep hours.
    /// 8h+ = 95-100, 7h = 80, 6h = 60, <5h = poor.
    private func computeSleepScore(hours: Double) -> Double {
        guard hours > 0 else { return 50 } // No data — neutral
        if hours >= 9.0 { return 100 }
        if hours >= 8.0 { return 90 + (hours - 8.0) * 10 }
        if hours >= 7.0 { return 75 + (hours - 7.0) * 15 }
        if hours >= 6.0 { return 55 + (hours - 6.0) * 20 }
        if hours >= 5.0 { return 35 + (hours - 5.0) * 20 }
        return max(10, hours * 7)
    }

    /// Scores resting heart rate.
    /// Lower is generally better for athletes: <50 bpm = excellent, 60-70 = normal.
    private func computeRestingHRScore(bpm: Double) -> Double {
        guard bpm > 0 else { return 50 } // No data — neutral
        if bpm <= 45 { return 100 }
        if bpm <= 50 { return 90 + (50 - bpm) * 2 }
        if bpm <= 55 { return 80 + (55 - bpm) * 2 }
        if bpm <= 60 { return 70 + (60 - bpm) * 2 }
        if bpm <= 70 { return 50 + (70 - bpm) * 2 }
        return max(10, 50 - (bpm - 70) * 2)
    }
}
