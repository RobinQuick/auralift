import Foundation
import CoreData
import SwiftUI

// MARK: - GuildRole

enum GuildRole: String, CaseIterable {
    case leader
    case officer
    case member

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .leader: return .neonGold
        case .officer: return .cyberOrange
        case .member: return .auraTextSecondary
        }
    }
}

// MARK: - GuildSummary

struct GuildSummary {
    let name: String
    let tag: String
    let memberCount: Int
    let averageLP: Int32
    let warRecord: (wins: Int32, losses: Int32)
    let role: GuildRole
    let joinDate: Date
}

// MARK: - ShareCardData

struct ShareCardData {
    let username: String
    let tier: RankTier
    let exerciseName: String
    let totalVolume: Double
    let setsCount: Int
    let averageFormScore: Double
    let peakVelocity: Double
    let lpEarned: Int32
    let xpEarned: Int32
    let goldenRatioScore: Double?
    let date: Date
}

// MARK: - SocialService

/// Local-first social service managing guild CRUD via CoreData
/// and generating shareable session cards.
final class SocialService: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Dependencies

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Guild CRUD

    /// Creates a new guild with the current user as leader.
    func createGuild(name: String, tag: String) -> GuildMembership? {
        guard !name.isEmpty else { return nil }

        // Check if user already has a guild
        guard fetchGuildMembership() == nil else { return nil }

        let guild = GuildMembership(context: context)
        guild.guildName = name
        guild.guildTag = tag.uppercased()
        guild.role = GuildRole.leader.rawValue
        guild.joinDate = Date()

        // Link to user profile
        if let profile = fetchUserProfile() {
            guild.userProfile = profile
        }

        do {
            try context.save()
            return guild
        } catch {
            context.rollback()
            return nil
        }
    }

    /// Joins an existing guild as a member.
    func joinGuild(name: String, tag: String) -> GuildMembership? {
        guard !name.isEmpty else { return nil }
        guard fetchGuildMembership() == nil else { return nil }

        let guild = GuildMembership(context: context)
        guild.guildName = name
        guild.guildTag = tag.uppercased()
        guild.role = GuildRole.member.rawValue
        guild.joinDate = Date()

        if let profile = fetchUserProfile() {
            guild.userProfile = profile
        }

        do {
            try context.save()
            return guild
        } catch {
            context.rollback()
            return nil
        }
    }

    /// Leaves the current guild by deleting the membership.
    func leaveGuild() {
        guard let membership = fetchGuildMembership() else { return }
        context.delete(membership)

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    /// Fetches a summary of the user's current guild.
    func fetchGuildSummary() -> GuildSummary? {
        guard let membership = fetchGuildMembership() else { return nil }

        let role = GuildRole(rawValue: membership.role ?? "member") ?? .member
        let profile = fetchUserProfile()
        let currentLP = profile?.currentLP ?? 0

        return GuildSummary(
            name: membership.guildName,
            tag: membership.guildTag ?? "",
            memberCount: 1, // Local-first: only current user
            averageLP: currentLP,
            warRecord: (wins: membership.guildWarWins, losses: membership.guildWarLosses),
            role: role,
            joinDate: membership.joinDate
        )
    }

    /// Updates the user's guild role.
    func updateGuildRole(_ role: GuildRole) {
        guard let membership = fetchGuildMembership() else { return }
        membership.role = role.rawValue

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    /// Records a guild war result.
    func recordGuildWarResult(won: Bool) {
        guard let membership = fetchGuildMembership() else { return }

        if won {
            membership.guildWarWins += 1
        } else {
            membership.guildWarLosses += 1
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - Share Card

    /// Builds share card data from a WorkoutViewModel's completed session.
    func buildShareCardData(
        exerciseName: String,
        completedSets: [SetSummary],
        sessionVolume: Double,
        sessionXP: Int32,
        workoutLP: Int32,
        sessionPeakVelocity: Double,
        averageFormScore: Double
    ) -> ShareCardData {
        let profile = fetchUserProfile()
        let username = profile?.username ?? "Athlete"
        let tier = RankTier(rawValue: profile?.currentRankTier ?? "iron") ?? .iron

        // Load golden ratio score from latest MorphoScan
        let goldenRatio = fetchLatestGoldenRatioScore()

        return ShareCardData(
            username: username,
            tier: tier,
            exerciseName: exerciseName,
            totalVolume: sessionVolume,
            setsCount: completedSets.count,
            averageFormScore: averageFormScore,
            peakVelocity: sessionPeakVelocity,
            lpEarned: workoutLP,
            xpEarned: sessionXP,
            goldenRatioScore: goldenRatio,
            date: Date()
        )
    }

    /// Renders a ShareCardView to UIImage using ImageRenderer.
    @MainActor
    func renderShareCard(_ data: ShareCardData) -> UIImage? {
        let cardView = ShareCardView(data: data)
        let renderer = ImageRenderer(content: cardView)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    // MARK: - Private Helpers

    private func fetchUserProfile() -> UserProfile? {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func fetchGuildMembership() -> GuildMembership? {
        let request = NSFetchRequest<GuildMembership>(entityName: "GuildMembership")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func fetchLatestGoldenRatioScore() -> Double? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MorphoScan")
        request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        request.fetchLimit = 1

        guard let scan = try? context.fetch(request).first,
              let score = scan.value(forKey: "goldenRatioScore") as? Double,
              score > 0 else { return nil }

        return score
    }
}
