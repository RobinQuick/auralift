import Foundation
import CoreData

// MARK: - Season Types

/// A season (battle pass) definition with timed duration and leveled rewards.
struct Season {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let levels: [SeasonLevel]
}

/// A single level in the season pass with XP threshold and dual-track rewards.
struct SeasonLevel {
    let level: Int
    let xpRequired: Int64
    let freeReward: SeasonReward?
    let premiumReward: SeasonReward?
}

/// A reward that can be claimed from the season pass.
struct SeasonReward: Identifiable {
    let id: String
    let type: RewardType
    let displayName: String
    let description: String
    let iconName: String
}

/// Types of cosmetic/functional rewards.
enum RewardType: String {
    case ghostSkin
    case profileFrame
    case appIcon
    case xpBoost
}

// MARK: - SeasonEngine

/// Manages season pass progression, XP tracking, level-ups, and reward claims.
@MainActor
final class SeasonEngine: ObservableObject {

    // MARK: - Singleton

    static let shared = SeasonEngine()

    // MARK: - Published State

    @Published var currentSeason: Season?

    // MARK: - Init

    private init() {
        loadCurrentSeason()
    }

    // MARK: - Season Loading

    func loadCurrentSeason() {
        currentSeason = Self.buildSeason0()
    }

    // MARK: - XP Management

    /// Adds XP to the user's season progress and handles level-ups.
    func addXP(_ xp: Int64, context: NSManagedObjectContext) {
        guard let progress = fetchOrCreateProgress(context: context),
              let season = currentSeason else { return }

        progress.userXP += xp

        // Check for level-ups
        let newLevel = calculateLevel(xp: progress.userXP, levels: season.levels)
        if newLevel > progress.currentLevel {
            progress.currentLevel = Int16(newLevel)
        }
        progress.lastUpdated = Date()

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - Reward Claims

    /// Claims a reward if the user has reached the required level and track.
    func claimReward(_ rewardId: String, isPro: Bool, context: NSManagedObjectContext) -> Bool {
        guard let progress = fetchOrCreateProgress(context: context),
              let season = currentSeason else { return false }

        // Already claimed?
        guard !progress.claimedRewardList.contains(rewardId) else { return false }

        // Find the level and track for this reward
        for level in season.levels {
            if let free = level.freeReward, free.id == rewardId {
                guard progress.currentLevel >= Int16(level.level) else { return false }
                progress.markRewardClaimed(rewardId)
                try? context.save()
                return true
            }
            if let premium = level.premiumReward, premium.id == rewardId {
                guard isPro, progress.currentLevel >= Int16(level.level) else { return false }
                progress.markRewardClaimed(rewardId)
                try? context.save()
                return true
            }
        }

        return false
    }

    // MARK: - Progress Calculation

    func getProgressToNextLevel(progress: SeasonProgress) -> (current: Int64, required: Int64) {
        guard let season = currentSeason else { return (0, 1) }

        let currentLvl = Int(progress.currentLevel)
        let totalXP = progress.userXP

        // Find XP threshold for current level
        let currentThreshold = season.levels.first { $0.level == currentLvl }?.xpRequired ?? 0

        // Find XP threshold for next level
        let nextLevel = season.levels.first { $0.level == currentLvl + 1 }
        let nextThreshold = nextLevel?.xpRequired ?? currentThreshold

        let xpInLevel = totalXP - currentThreshold
        let xpNeeded = nextThreshold - currentThreshold

        return (current: max(0, xpInLevel), required: max(1, xpNeeded))
    }

    // MARK: - Private Helpers

    private func calculateLevel(xp: Int64, levels: [SeasonLevel]) -> Int {
        var highestLevel = 1
        for level in levels where xp >= level.xpRequired {
            highestLevel = max(highestLevel, level.level)
        }
        return highestLevel
    }

    func fetchOrCreateProgress(context: NSManagedObjectContext) -> SeasonProgress? {
        let request = NSFetchRequest<SeasonProgress>(entityName: "SeasonProgress")
        request.fetchLimit = 1

        if let existing = try? context.fetch(request).first {
            return existing
        }

        // Create new progress
        let progress = SeasonProgress(context: context)
        progress.seasonId = currentSeason?.id ?? "season_0_alpha"

        // Link to user profile
        let profileRequest = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        if let profile = try? context.fetch(profileRequest).first {
            progress.userProfile = profile
        }

        try? context.save()
        return progress
    }

    // MARK: - Season 0 Definition

    static func buildSeason0() -> Season {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) ?? Date()
        let end = calendar.date(from: DateComponents(year: 2026, month: 3, day: 31)) ?? Date()

        let levels: [SeasonLevel] = [
            SeasonLevel(
                level: 1, xpRequired: 0,
                freeReward: SeasonReward(id: "s0_f1", type: .ghostSkin, displayName: "Ghost: Iron", description: "Gray ghost skeleton overlay", iconName: "figure.stand"),
                premiumReward: SeasonReward(id: "s0_p1", type: .xpBoost, displayName: "+10% XP Boost", description: "Earn 10% more XP per rep", iconName: "arrow.up.circle.fill")
            ),
            SeasonLevel(
                level: 2, xpRequired: 500,
                freeReward: nil,
                premiumReward: SeasonReward(id: "s0_p2", type: .profileFrame, displayName: "Neon Edge", description: "Neon blue profile frame", iconName: "square.on.circle")
            ),
            SeasonLevel(
                level: 3, xpRequired: 1_200,
                freeReward: SeasonReward(id: "s0_f3", type: .appIcon, displayName: "Cyber Mode", description: "Alternate app icon: Cyber Mode", iconName: "app.badge.fill"),
                premiumReward: nil
            ),
            SeasonLevel(
                level: 4, xpRequired: 2_000,
                freeReward: nil,
                premiumReward: SeasonReward(id: "s0_p4", type: .ghostSkin, displayName: "Ghost: Gold Glow", description: "Golden ghost skeleton overlay", iconName: "figure.stand")
            ),
            SeasonLevel(
                level: 5, xpRequired: 3_000,
                freeReward: SeasonReward(id: "s0_f5", type: .profileFrame, displayName: "Iron Border", description: "Iron-tier profile frame", iconName: "square.on.circle"),
                premiumReward: SeasonReward(id: "s0_p5", type: .xpBoost, displayName: "+20% XP Boost", description: "Earn 20% more XP per rep", iconName: "arrow.up.circle.fill")
            ),
            SeasonLevel(
                level: 6, xpRequired: 4_200,
                freeReward: nil,
                premiumReward: SeasonReward(id: "s0_p6", type: .appIcon, displayName: "Spartan Crest", description: "Alternate app icon: Spartan Crest", iconName: "app.badge.fill")
            ),
            SeasonLevel(
                level: 7, xpRequired: 5_500,
                freeReward: SeasonReward(id: "s0_f7", type: .ghostSkin, displayName: "Ghost: Neon Blue", description: "Neon blue ghost skeleton overlay", iconName: "figure.stand"),
                premiumReward: nil
            ),
            SeasonLevel(
                level: 8, xpRequired: 7_000,
                freeReward: nil,
                premiumReward: SeasonReward(id: "s0_p8", type: .profileFrame, displayName: "Diamond Edge", description: "Diamond-tier profile frame", iconName: "square.on.circle")
            ),
            SeasonLevel(
                level: 9, xpRequired: 8_800,
                freeReward: SeasonReward(id: "s0_f9", type: .appIcon, displayName: "Dark Titan", description: "Alternate app icon: Dark Titan", iconName: "app.badge.fill"),
                premiumReward: nil
            ),
            SeasonLevel(
                level: 10, xpRequired: 11_000,
                freeReward: SeasonReward(id: "s0_f10", type: .profileFrame, displayName: "Challenger", description: "Challenger-tier profile frame", iconName: "square.on.circle"),
                premiumReward: SeasonReward(id: "s0_p10", type: .ghostSkin, displayName: "Ghost: Mythic Purple", description: "Mythic purple ghost skeleton overlay", iconName: "figure.stand")
            ),
        ]

        return Season(
            id: "season_0_alpha",
            name: "ALPHA PROTOCOL",
            startDate: start,
            endDate: end,
            levels: levels
        )
    }
}
