import Foundation

/// Menstrual cycle phases for bio-adaptive training adjustments.
/// Used by CycleSyncService to modulate training intensity and volume.
enum CyclePhase: String, CaseIterable, Codable {
    case menstrual = "menstrual"
    case follicular = "follicular"
    case ovulatory = "ovulatory"
    case luteal = "luteal"

    var displayName: String {
        rawValue.capitalized
    }

    var dayRange: String {
        switch self {
        case .menstrual:    return "Days 1-5"
        case .follicular:   return "Days 6-13"
        case .ovulatory:    return "Days 14-16"
        case .luteal:       return "Days 17-28"
        }
    }

    /// Recommended training intensity modifier (1.0 = normal)
    var intensityModifier: Double {
        switch self {
        case .menstrual:    return 0.75
        case .follicular:   return 1.0
        case .ovulatory:    return 1.1
        case .luteal:       return 0.85
        }
    }

    /// Recommended volume modifier (1.0 = normal)
    var volumeModifier: Double {
        switch self {
        case .menstrual:    return 0.7
        case .follicular:   return 1.0
        case .ovulatory:    return 1.05
        case .luteal:       return 0.8
        }
    }

    var trainingGuidance: String {
        switch self {
        case .menstrual:
            return "Focus on lighter loads, mobility work, and recovery. Reduce volume by ~30%."
        case .follicular:
            return "Peak training window. Rising estrogen supports strength gains. Push PRs here."
        case .ovulatory:
            return "High energy and strength. Great for max effort attempts. Watch for joint laxity."
        case .luteal:
            return "Moderate intensity. Higher core temperature may affect endurance. Prioritize technique."
        }
    }
}
