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

        let levels = buildSeason0Levels()

        return Season(
            id: "season_0_alpha",
            name: "ALPHA PROTOCOL",
            startDate: start,
            endDate: end,
            levels: levels
        )
    }

    // MARK: - 50-Level Reward Table

    /// Builds 50 levels with escalating XP thresholds and alternating free/premium rewards.
    /// XP curve: level 1 = 0, then ~300 XP per level scaling up to ~1200 at level 50.
    /// Total XP to max: ~38,000 (achievable in ~3 months with daily play + quests).
    private static func buildSeason0Levels() -> [SeasonLevel] {
        // Reward pools
        let ghostSkins = [
            ("Iron", "Gray ghost skeleton"),
            ("Neon Blue", "Neon blue ghost skeleton"),
            ("Gold Glow", "Golden ghost skeleton"),
            ("Crimson", "Red neon ghost skeleton"),
            ("Emerald", "Green neon ghost skeleton"),
            ("Frost", "Ice-blue ghost skeleton"),
            ("Solar Flare", "Orange radiant ghost"),
            ("Void", "Dark purple ghost skeleton"),
            ("Plasma", "Electric white ghost"),
            ("Mythic Purple", "Mythic purple ghost skeleton"),
        ]

        let profileFrames = [
            ("Iron Border", "Iron-tier profile frame"),
            ("Neon Edge", "Neon blue profile frame"),
            ("Gold Ring", "Gold accent profile frame"),
            ("Diamond Edge", "Diamond-tier profile frame"),
            ("Crimson Halo", "Red neon profile frame"),
            ("Emerald Crown", "Green elite profile frame"),
            ("Frost Aura", "Ice-blue profile frame"),
            ("Solar Frame", "Radiant orange profile frame"),
            ("Void Border", "Dark purple profile frame"),
            ("Challenger", "Challenger-tier profile frame"),
        ]

        let appIcons = [
            ("Cyber Mode", "Alternate app icon: Cyber Mode"),
            ("Spartan Crest", "Alternate app icon: Spartan Crest"),
            ("Dark Titan", "Alternate app icon: Dark Titan"),
            ("Neon Skull", "Alternate app icon: Neon Skull"),
            ("Phoenix", "Alternate app icon: Phoenix"),
        ]

        var levels: [SeasonLevel] = []
        var ghostIdx = 0
        var frameIdx = 0
        var iconIdx = 0

        for lvl in 1...50 {
            // XP curve: base 300 + 18 * level (ramps from 318 to 1200)
            let xp: Int64 = lvl == 1 ? 0 : Int64(300 * (lvl - 1)) + Int64(9 * (lvl - 1) * (lvl - 1) / 50)

            var freeReward: SeasonReward?
            var premiumReward: SeasonReward?

            // Distribute rewards across levels:
            // Every 5 levels: milestone with both tracks
            // Odd levels: free track reward
            // Even levels: premium track reward
            // Levels with no reward on a track: nil

            if lvl % 10 == 0 {
                // Milestone levels (10, 20, 30, 40, 50): both tracks, ghost skins
                let gIdx = min(ghostIdx, ghostSkins.count - 1)
                freeReward = SeasonReward(
                    id: "s0_f\(lvl)", type: .ghostSkin,
                    displayName: "Ghost: \(ghostSkins[gIdx].0)",
                    description: ghostSkins[gIdx].1,
                    iconName: "figure.stand"
                )
                ghostIdx += 1

                let fIdx = min(frameIdx, profileFrames.count - 1)
                premiumReward = SeasonReward(
                    id: "s0_p\(lvl)", type: .profileFrame,
                    displayName: profileFrames[fIdx].0,
                    description: profileFrames[fIdx].1,
                    iconName: "square.on.circle"
                )
                frameIdx += 1
            } else if lvl % 5 == 0 {
                // Every 5th level: XP boost (premium) + app icon (free)
                if iconIdx < appIcons.count {
                    freeReward = SeasonReward(
                        id: "s0_f\(lvl)", type: .appIcon,
                        displayName: appIcons[iconIdx].0,
                        description: appIcons[iconIdx].1,
                        iconName: "app.badge.fill"
                    )
                    iconIdx += 1
                }
                let boostPercent = min(10 + (lvl / 5) * 5, 50)
                premiumReward = SeasonReward(
                    id: "s0_p\(lvl)", type: .xpBoost,
                    displayName: "+\(boostPercent)% XP Boost",
                    description: "Earn \(boostPercent)% more XP per rep",
                    iconName: "arrow.up.circle.fill"
                )
            } else if lvl % 3 == 0 {
                // Every 3rd level: profile frame (alternates free/premium)
                let fIdx = min(frameIdx, profileFrames.count - 1)
                if lvl % 6 == 0 {
                    premiumReward = SeasonReward(
                        id: "s0_p\(lvl)", type: .profileFrame,
                        displayName: profileFrames[fIdx].0,
                        description: profileFrames[fIdx].1,
                        iconName: "square.on.circle"
                    )
                } else {
                    freeReward = SeasonReward(
                        id: "s0_f\(lvl)", type: .profileFrame,
                        displayName: profileFrames[fIdx].0,
                        description: profileFrames[fIdx].1,
                        iconName: "square.on.circle"
                    )
                }
                frameIdx = (frameIdx + 1) % profileFrames.count
            } else if lvl % 7 == 0 {
                // Every 7th level: ghost skin (premium)
                let gIdx = min(ghostIdx, ghostSkins.count - 1)
                premiumReward = SeasonReward(
                    id: "s0_p\(lvl)", type: .ghostSkin,
                    displayName: "Ghost: \(ghostSkins[gIdx].0)",
                    description: ghostSkins[gIdx].1,
                    iconName: "figure.stand"
                )
                ghostIdx = (ghostIdx + 1) % ghostSkins.count
            }
            // Remaining levels have no rewards (empty rows)

            levels.append(SeasonLevel(
                level: lvl,
                xpRequired: xp,
                freeReward: freeReward,
                premiumReward: premiumReward
            ))
        }

        return levels
    }
}
