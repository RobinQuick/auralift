import Foundation
import CoreData
import Combine

// MARK: - StreakTier

/// Visual tiers for the Cyber-Streak flame based on consecutive days.
enum StreakTier: Int, CaseIterable {
    case none = 0       // 0 days
    case spark = 1      // 1-2 days: faint blue flame
    case burning = 3    // 3-6 days: medium blue flame
    case blazing = 7    // 7-13 days: intense purple flame + x1.5 XP
    case infernal = 14  // 14-29 days: bright purple flame + x2.0 XP
    case mythic = 30    // 30+ days: golden flame + x2.5 XP

    var xpMultiplier: Double {
        switch self {
        case .none: return 1.0
        case .spark: return 1.0
        case .burning: return 1.2
        case .blazing: return 1.5
        case .infernal: return 2.0
        case .mythic: return 2.5
        }
    }

    var flameIcon: String {
        switch self {
        case .none: return "flame"
        case .spark, .burning: return "flame.fill"
        case .blazing, .infernal, .mythic: return "flame.fill"
        }
    }

    var flameColor: String {
        switch self {
        case .none: return "auraTextDisabled"
        case .spark: return "neonBlue"
        case .burning: return "neonBlue"
        case .blazing: return "neonPurple"
        case .infernal: return "neonPurple"
        case .mythic: return "neonGold"
        }
    }

    var label: String {
        switch self {
        case .none: return "Inactif"
        case .spark: return "Étincelle"
        case .burning: return "En feu"
        case .blazing: return "Flamme intense"
        case .infernal: return "Infernal"
        case .mythic: return "Mythique"
        }
    }

    static func from(days: Int) -> StreakTier {
        if days >= 30 { return .mythic }
        if days >= 14 { return .infernal }
        if days >= 7 { return .blazing }
        if days >= 3 { return .burning }
        if days >= 1 { return .spark }
        return .none
    }
}

// MARK: - CyberStreakManager

/// Tracks consecutive days of activity (workout or active recovery).
/// Provides XP multiplier, streak freeze (PRO), and loss aversion alerts.
@MainActor
final class CyberStreakManager: ObservableObject {

    // MARK: - Singleton

    static let shared = CyberStreakManager()

    // MARK: - UserDefaults Keys

    private static let streakCountKey = "com.aurea.streak.count"
    private static let lastActiveDateKey = "com.aurea.streak.lastActiveDate"
    private static let freezeUsedMonthKey = "com.aurea.streak.freezeUsedMonth"

    // MARK: - Published State

    @Published var currentStreak: Int = 0
    @Published var streakTier: StreakTier = .none
    @Published var isAtRisk: Bool = false
    @Published var freezeAvailable: Bool = false

    // MARK: - Init

    private init() {
        loadStreak()
    }

    // MARK: - Load

    func loadStreak() {
        let defaults = UserDefaults.standard
        let stored = defaults.integer(forKey: Self.streakCountKey)
        let lastActiveInterval = defaults.double(forKey: Self.lastActiveDateKey)

        guard lastActiveInterval > 0 else {
            currentStreak = 0
            streakTier = .none
            isAtRisk = false
            updateFreezeAvailability()
            return
        }

        let lastActive = Date(timeIntervalSince1970: lastActiveInterval)
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let lastDay = calendar.startOfDay(for: lastActive)

        let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

        if daysDiff == 0 {
            // Active today — streak intact
            currentStreak = stored
        } else if daysDiff == 1 {
            // Yesterday — streak alive but at risk if no activity today
            currentStreak = stored
            isAtRisk = true
        } else {
            // Missed more than 1 day — streak broken (unless freeze)
            currentStreak = 0
            saveStreak()
        }

        streakTier = StreakTier.from(days: currentStreak)
        updateFreezeAvailability()
    }

    // MARK: - Record Activity

    /// Call when user completes a workout or logs active recovery.
    func recordActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        let lastActiveInterval = defaults.double(forKey: Self.lastActiveDateKey)

        if lastActiveInterval > 0 {
            let lastActive = Date(timeIntervalSince1970: lastActiveInterval)
            let lastDay = calendar.startOfDay(for: lastActive)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if daysDiff == 0 {
                // Already recorded today
                return
            } else if daysDiff == 1 {
                // Consecutive day — increment
                currentStreak += 1
            } else {
                // Gap — start fresh
                currentStreak = 1
            }
        } else {
            // First ever activity
            currentStreak = 1
        }

        isAtRisk = false
        streakTier = StreakTier.from(days: currentStreak)

        defaults.set(today.timeIntervalSince1970, forKey: Self.lastActiveDateKey)
        saveStreak()
    }

    // MARK: - Streak Freeze (PRO only)

    /// Uses the monthly streak freeze to protect the streak.
    /// Returns true if freeze was applied.
    func useStreakFreeze() -> Bool {
        guard PremiumManager.shared.isPro else { return false }
        guard freezeAvailable else { return false }

        // Mark freeze used for this month
        let monthKey = currentMonthKey()
        UserDefaults.standard.set(true, forKey: Self.freezeUsedMonthKey + "." + monthKey)

        // Extend last active date to today
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today.timeIntervalSince1970, forKey: Self.lastActiveDateKey)

        isAtRisk = false
        freezeAvailable = false
        return true
    }

    // MARK: - XP Multiplier

    var xpMultiplier: Double {
        streakTier.xpMultiplier
    }

    // MARK: - Private Helpers

    private func saveStreak() {
        UserDefaults.standard.set(currentStreak, forKey: Self.streakCountKey)
    }

    private func updateFreezeAvailability() {
        let monthKey = currentMonthKey()
        let used = UserDefaults.standard.bool(forKey: Self.freezeUsedMonthKey + "." + monthKey)
        freezeAvailable = PremiumManager.shared.isPro && !used
    }

    private func currentMonthKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }

    // MARK: - Reset (for account deletion)

    func reset() {
        currentStreak = 0
        streakTier = .none
        isAtRisk = false
        UserDefaults.standard.removeObject(forKey: Self.streakCountKey)
        UserDefaults.standard.removeObject(forKey: Self.lastActiveDateKey)
    }
}
