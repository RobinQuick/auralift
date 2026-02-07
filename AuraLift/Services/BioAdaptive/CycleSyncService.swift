import Foundation
import HealthKit

/// Adapts training recommendations based on menstrual cycle phase.
/// Uses HealthKit menstrual cycle data when available, falls back to manual tracking.
final class CycleSyncService: ServiceProtocol {

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let healthStore = HKHealthStore()

    // MARK: - HealthKit Types

    private var menstrualFlowType: HKCategoryType? {
        HKCategoryType.categoryType(forIdentifier: .menstrualFlow)
    }

    // MARK: - Initialize

    func initialize() async throws {
        guard isAvailable, let flowType = menstrualFlowType else { return }
        try await healthStore.requestAuthorization(toShare: [], read: [flowType])
    }

    // MARK: - Fetch Current Phase

    /// Determines the current cycle phase from HealthKit menstrual flow data.
    /// Falls back to manual cycle day if no HealthKit data is available.
    func fetchCurrentPhase() async -> CyclePhase? {
        guard isAvailable, let flowType = menstrualFlowType else { return nil }

        // Look back 45 days for the most recent menstrual flow start
        let calendar = Calendar.current
        let now = Date()
        let lookbackStart = calendar.date(byAdding: .day, value: -45, to: now) ?? now

        let predicate = HKQuery.predicateForSamples(
            withStart: lookbackStart,
            end: now,
            options: .strictEndDate
        )
        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: flowType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            healthStore.execute(query)
        }

        guard !samples.isEmpty else { return nil }

        // Find the most recent period start (first flow sample in the latest cycle)
        let lastPeriodStart = findLastPeriodStart(from: samples)
        guard let cycleStart = lastPeriodStart else { return nil }

        let daysSincePeriodStart = calendar.dateComponents([.day], from: cycleStart, to: now).day ?? 0

        return phaseFromCycleDay(daysSincePeriodStart + 1) // Day 1-based
    }

    /// Returns training adjustment based on the current cycle phase.
    func phaseAdjustments(for phase: CyclePhase) -> TrainingAdjustment {
        TrainingAdjustment(
            volumeModifier: phase.volumeModifier,
            intensityModifier: phase.intensityModifier,
            recommendation: phase.trainingGuidance,
            shouldDeload: phase == .menstrual
        )
    }

    /// Determines the current phase from a manual cycle day input.
    /// Useful when HealthKit data is not available.
    func phaseFromManualCycleDay(_ day: Int) -> CyclePhase {
        phaseFromCycleDay(day)
    }

    // MARK: - Cycle Phase Mapping

    /// Maps a cycle day (1-based) to a CyclePhase.
    /// Uses standard 28-day cycle model:
    /// - Days 1-5: Menstrual
    /// - Days 6-13: Follicular
    /// - Days 14-16: Ovulatory
    /// - Days 17-28: Luteal
    private func phaseFromCycleDay(_ day: Int) -> CyclePhase {
        // Normalize to 28-day cycle
        let normalizedDay = ((day - 1) % 28) + 1

        switch normalizedDay {
        case 1...5:    return .menstrual
        case 6...13:   return .follicular
        case 14...16:  return .ovulatory
        case 17...28:  return .luteal
        default:       return .follicular
        }
    }

    // MARK: - Period Detection

    /// Finds the start date of the most recent menstrual period from flow samples.
    /// Groups consecutive flow days, takes the earliest day of the latest group.
    private func findLastPeriodStart(from samples: [HKCategorySample]) -> Date? {
        guard !samples.isEmpty else { return nil }

        let calendar = Calendar.current

        // Sort by date ascending
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        // Group consecutive flow days into period clusters (gap > 7 days = new period)
        var periods: [[HKCategorySample]] = []
        var currentPeriod: [HKCategorySample] = [sorted[0]]

        for i in 1..<sorted.count {
            let gap = calendar.dateComponents(
                [.day],
                from: sorted[i - 1].startDate,
                to: sorted[i].startDate
            ).day ?? 0

            if gap > 7 {
                periods.append(currentPeriod)
                currentPeriod = [sorted[i]]
            } else {
                currentPeriod.append(sorted[i])
            }
        }
        periods.append(currentPeriod)

        // Return the start of the most recent period
        return periods.last?.first?.startDate
    }

    // MARK: - Cycle Length Estimation

    /// Estimates average cycle length from historical data.
    /// Returns 28 if insufficient data.
    func estimateCycleLength(from samples: [HKCategorySample]) -> Int {
        let calendar = Calendar.current
        let sorted = samples.sorted { $0.startDate < $1.startDate }

        // Find period starts
        var periodStarts: [Date] = []
        if let first = sorted.first {
            periodStarts.append(first.startDate)
        }

        for i in 1..<sorted.count {
            let gap = calendar.dateComponents(
                [.day],
                from: sorted[i - 1].startDate,
                to: sorted[i].startDate
            ).day ?? 0

            if gap > 7 {
                periodStarts.append(sorted[i].startDate)
            }
        }

        guard periodStarts.count >= 2 else { return 28 }

        // Average gap between period starts
        var totalDays = 0
        for i in 1..<periodStarts.count {
            let days = calendar.dateComponents([.day], from: periodStarts[i - 1], to: periodStarts[i]).day ?? 28
            totalDays += days
        }

        let avgLength = totalDays / (periodStarts.count - 1)
        return max(21, min(35, avgLength)) // Clamp to physiological range
    }
}
