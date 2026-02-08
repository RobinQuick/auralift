import Foundation
import SwiftUI

// MARK: - PrestigeTier

/// Prestige league tiers — progression from Member to Architect (Black Card).
enum PrestigeTier: String, CaseIterable {
    case member = "Member"
    case initiate = "Initiate"
    case adept = "Adept"
    case sentinel = "Sentinel"
    case elite = "Elite"
    case architect = "Architect"

    var displayName: String { rawValue }

    var pointsRequired: Int {
        switch self {
        case .member:    return 0
        case .initiate:  return 500
        case .adept:     return 1500
        case .sentinel:  return 3500
        case .elite:     return 7000
        case .architect: return 15000
        }
    }

    var iconName: String {
        switch self {
        case .member:    return "person.fill"
        case .initiate:  return "star.fill"
        case .adept:     return "star.circle.fill"
        case .sentinel:  return "shield.fill"
        case .elite:     return "crown.fill"
        case .architect: return "building.columns.fill"
        }
    }

    /// Next tier in the progression, nil for Architect.
    var next: PrestigeTier? {
        let all = PrestigeTier.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }
}

// MARK: - AureaLeague

/// Manages the prestige league system: session scoring, tier promotion, and season resets.
final class AureaLeague: ObservableObject {

    // MARK: - State

    @Published var currentTier: PrestigeTier = .member
    @Published var prestigePoints: Int = 0
    @Published var currentSeasonId: String = "S1"

    // MARK: - Black Card

    /// True for Architect tier — unlocks exclusive UI elements.
    var isBlackCard: Bool { currentTier == .architect }

    // MARK: - Init

    init() {
        loadState()
    }

    // MARK: - Record Session

    /// Awards prestige points based on session quality metrics.
    /// quality: 0-100 form score, consistency: days this week, formScore: avg form.
    func recordSession(quality: Double, consistency: Int, formScore: Double) {
        // Base: quality / 10 (max 10 pts)
        var points = Int(quality / 10.0)

        // Consistency bonus: +2 per training day this week (max +8)
        points += min(consistency, 4) * 2

        // Form bonus: >90% form → +5
        if formScore >= 90 {
            points += 5
        } else if formScore >= 80 {
            points += 3
        }

        prestigePoints += points
        saveState()
    }

    // MARK: - Check Promotion

    /// Returns the new tier if a promotion threshold was crossed, nil otherwise.
    func checkPromotion() -> PrestigeTier? {
        guard let nextTier = currentTier.next,
              prestigePoints >= nextTier.pointsRequired else { return nil }
        currentTier = nextTier
        saveState()
        return nextTier
    }

    // MARK: - Season Reset

    /// Resets prestige points for a new season with a loyalty bonus.
    /// Keeps tier but resets points to 10% of previous (loyalty).
    func seasonReset(newSeasonId: String) {
        let loyaltyBonus = prestigePoints / 10
        prestigePoints = loyaltyBonus
        currentSeasonId = newSeasonId

        // Don't demote — tier is permanent until seasonal decay (future feature)
        saveState()
    }

    // MARK: - Progress

    /// Progress toward the next tier as a 0.0-1.0 fraction.
    var progressToNextTier: Double {
        guard let next = currentTier.next else { return 1.0 }
        let currentRequired = currentTier.pointsRequired
        let nextRequired = next.pointsRequired
        let range = nextRequired - currentRequired
        guard range > 0 else { return 1.0 }
        return min(1.0, Double(prestigePoints - currentRequired) / Double(range))
    }

    /// Points remaining to reach the next tier.
    var pointsToNextTier: Int {
        guard let next = currentTier.next else { return 0 }
        return max(0, next.pointsRequired - prestigePoints)
    }

    // MARK: - Persistence

    private func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(currentTier.rawValue, forKey: "league.tier")
        defaults.set(prestigePoints, forKey: "league.points")
        defaults.set(currentSeasonId, forKey: "league.seasonId")
    }

    private func loadState() {
        let defaults = UserDefaults.standard
        let tierRaw = defaults.string(forKey: "league.tier") ?? ""
        currentTier = PrestigeTier(rawValue: tierRaw) ?? .member
        prestigePoints = defaults.integer(forKey: "league.points")
        currentSeasonId = defaults.string(forKey: "league.seasonId").flatMap { $0.isEmpty ? nil : $0 } ?? "S1"
    }
}
