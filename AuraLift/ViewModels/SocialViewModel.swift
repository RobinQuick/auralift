import Foundation
import CoreData
import SwiftUI

// MARK: - SocialViewModel

@MainActor
class SocialViewModel: ObservableObject {

    // MARK: - Published State

    @Published var guildSummary: GuildSummary?
    @Published var isInGuild: Bool = false
    @Published var recentSessions: [RankSnapshot] = []
    @Published var shareCardImage: UIImage?
    @Published var showCreateGuild: Bool = false
    @Published var showShareSheet: Bool = false

    // Guild creation fields
    @Published var newGuildName: String = ""
    @Published var newGuildTag: String = ""

    // MARK: - Dependencies

    private let socialService: SocialService
    private let leaderboardService: LeaderboardService

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.socialService = SocialService(context: context)
        self.leaderboardService = LeaderboardService(context: context)
    }

    // MARK: - Data Loading

    func loadData() {
        guildSummary = socialService.fetchGuildSummary()
        isInGuild = guildSummary != nil
        recentSessions = leaderboardService.fetchRankHistory(limit: 10)
    }

    // MARK: - Guild Actions

    func createGuild() {
        guard !newGuildName.isEmpty else { return }

        let tag = newGuildTag.isEmpty ? String(newGuildName.prefix(3)).uppercased() : newGuildTag
        let _ = socialService.createGuild(name: newGuildName, tag: tag)

        newGuildName = ""
        newGuildTag = ""
        showCreateGuild = false
        loadData()
    }

    func leaveGuild() {
        socialService.leaveGuild()
        loadData()
    }

    // MARK: - Share Card

    func generateShareCard(
        exerciseName: String,
        completedSets: [SetSummary],
        sessionVolume: Double,
        sessionXP: Int32,
        workoutLP: Int32,
        sessionPeakVelocity: Double,
        averageFormScore: Double
    ) {
        let data = socialService.buildShareCardData(
            exerciseName: exerciseName,
            completedSets: completedSets,
            sessionVolume: sessionVolume,
            sessionXP: sessionXP,
            workoutLP: workoutLP,
            sessionPeakVelocity: sessionPeakVelocity,
            averageFormScore: averageFormScore
        )
        shareCardImage = socialService.renderShareCard(data)
    }

    /// Generates a share card from a recent session snapshot for quick sharing.
    func generateQuickShareCard() {
        guard let latest = recentSessions.first else { return }

        let data = ShareCardData(
            username: "Athlete",
            tier: latest.tier,
            exerciseName: "Session",
            totalVolume: 0,
            setsCount: 0,
            averageFormScore: latest.formQualityAverage,
            peakVelocity: latest.velocityScore,
            lpEarned: latest.lp,
            xpEarned: 0,
            goldenRatioScore: nil,
            date: latest.date
        )
        shareCardImage = socialService.renderShareCard(data)
    }
}
