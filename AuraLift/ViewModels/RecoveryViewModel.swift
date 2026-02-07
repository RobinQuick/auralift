import Foundation
import CoreData
import SwiftUI

@MainActor
class RecoveryViewModel: ObservableObject {

    // MARK: - Published State

    @Published var overallReadiness: Double = 100
    @Published var readinessLevel: ReadinessLevel = .optimal
    @Published var hrvValue: Double = 0
    @Published var hrvBaseline: Double = 0
    @Published var sleepHours: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var muscleRecoveryScores: [String: Double] = [:]
    @Published var muscleStatuses: [MuscleRecoveryStatus] = []
    @Published var selectedMuscle: String?
    @Published var cyclePhase: CyclePhase?
    @Published var trainingAdjustment: TrainingAdjustment?
    @Published var deloadRecommendation: DeloadRecommendation?
    @Published var isLoading: Bool = false

    // MARK: - Component Scores

    @Published var hrvScore: Double = 0
    @Published var sleepScore: Double = 0
    @Published var restingHRScore: Double = 0
    @Published var muscleRecoveryAverage: Double = 100

    // MARK: - Services

    private let healthKitManager = HealthKitManager()
    private let bioAdaptiveService = BioAdaptiveService()
    private let heatmapEngine = RecoveryHeatmapEngine()
    private let cycleSyncService = CycleSyncService()

    private let context: NSManagedObjectContext

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        loadCachedData()
    }

    // MARK: - Load Cached Data (Synchronous)

    /// Loads the most recent snapshot from CoreData for instant display.
    func loadCachedData() {
        // Load latest recovery snapshot
        let request = NSFetchRequest<NSManagedObject>(entityName: "RecoverySnapshot")
        request.sortDescriptors = [NSSortDescriptor(key: "snapshotDate", ascending: false)]
        request.fetchLimit = 1

        if let snapshot = try? context.fetch(request).first {
            overallReadiness = (snapshot.value(forKey: "overallReadiness") as? Double) ?? 100
            hrvValue = (snapshot.value(forKey: "hrvValue") as? Double) ?? 0
            sleepHours = (snapshot.value(forKey: "sleepHours") as? Double) ?? 0
            restingHeartRate = (snapshot.value(forKey: "restingHeartRate") as? Double) ?? 0
            activeEnergy = (snapshot.value(forKey: "activeEnergyBurned") as? Double) ?? 0

            if let phaseString = snapshot.value(forKey: "cyclePhase") as? String {
                cyclePhase = CyclePhase(rawValue: phaseString)
            }
        }

        // Load muscle recovery from heatmap engine
        muscleStatuses = heatmapEngine.generateHeatmap(context: context)
        for status in muscleStatuses {
            muscleRecoveryScores[status.muscleName] = status.recoveryPercent
        }
        muscleRecoveryAverage = computeMuscleAverage()
    }

    // MARK: - Full Refresh (Async — HealthKit + Services)

    /// Performs a full refresh: fetches HealthKit data, computes readiness, checks deload.
    func refreshData() async {
        isLoading = true
        defer { isLoading = false }

        // 1. Fetch HealthKit snapshot
        let snapshot: HealthSnapshot
        if healthKitManager.isAvailable {
            try? await healthKitManager.initialize()
            snapshot = await healthKitManager.fetchLatestSnapshot()
        } else {
            snapshot = HealthSnapshot(hrv: hrvValue, sleepHours: sleepHours, restingHR: restingHeartRate, activeEnergy: activeEnergy)
        }

        hrvValue = snapshot.hrv
        sleepHours = snapshot.sleepHours
        restingHeartRate = snapshot.restingHR
        activeEnergy = snapshot.activeEnergy

        // 2. Compute HRV baseline from 14-day history
        if healthKitManager.isAvailable {
            let hrvHistory = await healthKitManager.fetchHRVHistory(days: 14)
            hrvBaseline = bioAdaptiveService.computeHRVBaseline(from: hrvHistory)
        }

        // 3. Fetch cycle phase
        if cycleSyncService.isAvailable {
            try? await cycleSyncService.initialize()
            cyclePhase = await cycleSyncService.fetchCurrentPhase()
        }

        // 4. Update muscle recovery heatmap
        muscleStatuses = heatmapEngine.generateHeatmap(context: context)
        muscleRecoveryScores = [:]
        for status in muscleStatuses {
            muscleRecoveryScores[status.muscleName] = status.recoveryPercent
        }
        muscleRecoveryAverage = computeMuscleAverage()

        // 5. Calculate readiness
        let assessment = bioAdaptiveService.calculateReadiness(
            snapshot: snapshot,
            hrvBaseline: hrvBaseline,
            muscleRecoveryAverage: muscleRecoveryAverage,
            cyclePhase: cyclePhase
        )

        overallReadiness = assessment.overallScore
        readinessLevel = assessment.readinessLevel
        hrvScore = assessment.hrvScore
        sleepScore = assessment.sleepScore
        restingHRScore = assessment.restingHRScore
        trainingAdjustment = assessment.adjustment

        // 6. Evaluate deload
        let velocities = bioAdaptiveService.fetchRecentSessionVelocities(context: context)
        deloadRecommendation = bioAdaptiveService.evaluateDeload(
            snapshot: snapshot,
            hrvBaseline: hrvBaseline,
            recentSessionVelocities: velocities,
            recentSleepHours: [] // TODO: Historical sleep from HealthKit
        )

        // 7. Save snapshot to CoreData
        bioAdaptiveService.saveSnapshot(
            assessment: assessment,
            snapshot: snapshot,
            cyclePhase: cyclePhase,
            context: context
        )
    }

    // MARK: - Helpers

    private func computeMuscleAverage() -> Double {
        guard !muscleRecoveryScores.isEmpty else { return 100 }
        let sum = muscleRecoveryScores.values.reduce(0, +)
        return sum / Double(muscleRecoveryScores.count)
    }

    /// Returns sorted muscle statuses by region for display.
    func musclesByRegion(_ region: String) -> [MuscleRecoveryStatus] {
        muscleStatuses
            .filter { $0.bodyRegion == region }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
    }

    /// Returns the most fatigued muscles (recovery < 50%).
    var fatiguedMuscles: [MuscleRecoveryStatus] {
        muscleStatuses
            .filter { $0.recoveryPercent < 50 }
            .sorted { $0.recoveryPercent < $1.recoveryPercent }
    }

    /// Returns the color for a readiness score.
    var readinessColor: Color {
        if overallReadiness >= 85 { return .neonGreen }
        if overallReadiness >= 70 { return .neonBlue }
        if overallReadiness >= 50 { return .cyberOrange }
        return .neonRed
    }
}
