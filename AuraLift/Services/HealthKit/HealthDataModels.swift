import Foundation

/// A point-in-time snapshot of the user's key health metrics from HealthKit.
struct HealthSnapshot {
    let hrv: Double            // HRV SDNN in milliseconds
    let sleepHours: Double     // Total sleep hours (last night)
    let restingHR: Double      // Resting heart rate in bpm
    let activeEnergy: Double   // Active energy burned in kcal (today)

    /// Whether the snapshot has meaningful data.
    var hasData: Bool {
        hrv > 0 || sleepHours > 0 || restingHR > 0
    }
}

/// Represents a single HRV reading with its timestamp.
struct HRVReading {
    let value: Double     // SDNN in milliseconds
    let timestamp: Date
}

/// Represents a sleep session with duration and quality classification.
struct SleepSession {
    let startDate: Date
    let endDate: Date
    let quality: SleepQuality

    var durationHours: Double {
        endDate.timeIntervalSince(startDate) / 3600.0
    }
}

/// Sleep quality classification.
enum SleepQuality: String, Codable {
    case poor
    case fair
    case good
    case excellent

    static func from(hours: Double) -> SleepQuality {
        if hours >= 8.0 { return .excellent }
        if hours >= 7.0 { return .good }
        if hours >= 6.0 { return .fair }
        return .poor
    }
}

/// Training load adjustment based on readiness.
struct TrainingAdjustment {
    let volumeModifier: Double      // 0.0 to 1.2 (1.0 = normal)
    let intensityModifier: Double   // 0.0 to 1.1 (1.0 = normal)
    let recommendation: String      // Human-readable guidance
    let shouldDeload: Bool          // Auto-deload recommendation
}
