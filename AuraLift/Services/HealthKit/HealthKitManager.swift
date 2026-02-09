import Foundation
import HealthKit

/// Manages HealthKit authorization and data queries for biometric signals.
/// Centralizes all HealthKit read/write operations for the app.
final class HealthKitManager: ServiceProtocol {

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let healthStore = HKHealthStore()

    // MARK: - Data Types

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        if let hrv = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            types.insert(hrv)
        }
        if let rhr = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(rhr)
        }
        if let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(energy)
        }
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        return types
    }()

    // MARK: - Initialize

    func initialize() async throws {
        guard isAvailable else { return }
        try await requestAuthorization()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Fetch Latest Snapshot

    /// Fetches the latest health snapshot with HRV, sleep, HR, and energy data.
    func fetchLatestSnapshot() async -> HealthSnapshot {
        async let hrv = fetchLatestHRV()
        async let rhr = fetchLatestRestingHR()
        async let sleep = fetchLastNightSleep()
        async let energy = fetchTodayActiveEnergy()

        return await HealthSnapshot(
            hrv: hrv,
            sleepHours: sleep,
            restingHR: rhr,
            activeEnergy: energy
        )
    }

    // MARK: - HRV

    /// Fetches the most recent HRV (SDNN) value in milliseconds.
    func fetchLatestHRV() async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return 0
        }
        return await fetchLatestQuantity(quantityType, unit: HKUnit.secondUnit(with: .milli))
    }

    /// Fetches HRV readings from the last N days for trend analysis.
    func fetchHRVHistory(days: Int = 14) async -> [HRVReading] {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else {
            return []
        }

        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let readings = (samples as? [HKQuantitySample])?.map { sample in
                    HRVReading(
                        value: sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                        timestamp: sample.startDate
                    )
                } ?? []
                continuation.resume(returning: readings)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Resting Heart Rate

    /// Fetches the most recent resting heart rate in bpm.
    func fetchLatestRestingHR() async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return 0
        }
        return await fetchLatestQuantity(quantityType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    // MARK: - Sleep

    /// Fetches last night's total sleep hours.
    func fetchLastNightSleep() async -> Double {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return 0
        }

        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let sleepWindowStart = calendar.date(byAdding: .hour, value: -14, to: startOfDay) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: sleepWindowStart, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }

                // Sum asleep stages (exclude inBed)
                let totalSeconds = sleepSamples
                    .filter { $0.value != HKCategoryValueSleepAnalysis.inBed.rawValue }
                    .reduce(0.0) { total, sample in
                        total + sample.endDate.timeIntervalSince(sample.startDate)
                    }

                continuation.resume(returning: totalSeconds / 3600.0)
            }
            healthStore.execute(query)
        }
    }

    /// Fetches sleep duration history for the last N nights in hours.
    /// Each element represents one night, newest first.
    func fetchRecentSleepHistory(days: Int = 7) async -> [Double] {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return []
        }

        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: now) ?? now

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                    continuation.resume(returning: [])
                    return
                }

                var nightlySleep: [Date: Double] = [:]
                for sample in sleepSamples where sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                    let normalizedNight = self.nightAnchor(for: sample.startDate, calendar: calendar)
                    let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
                    nightlySleep[normalizedNight, default: 0] += duration
                }

                let ordered = nightlySleep
                    .sorted { $0.key > $1.key }
                    .map(\.value)
                continuation.resume(returning: ordered)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Active Energy

    /// Fetches today's total active energy burned in kcal.
    func fetchTodayActiveEnergy() async -> Double {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return 0
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, _ in
                let total = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: total)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Helpers

    private func fetchLatestQuantity(_ quantityType: HKQuantityType, unit: HKUnit) async -> Double {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    /// Normalizes a sleep sample date to a night bucket (18:00 → next day considered same night).
    private func nightAnchor(for date: Date, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: date)
        if hour < 18 {
            return calendar.startOfDay(for: date)
        }
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        return calendar.startOfDay(for: nextDay)
    }
}
