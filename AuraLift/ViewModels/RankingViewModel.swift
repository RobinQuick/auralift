import Foundation
import CoreData
import SwiftUI

@MainActor
class RankingViewModel: ObservableObject {

    // MARK: - Tier & LP State

    @Published var currentTier: RankTier = .iron
    @Published var currentLP: Int32 = 0
    @Published var lpInTier: Int32 = 0
    @Published var lpToNextTier: Int32 = 100
    @Published var lpProgress: Double = 0

    // MARK: - Rank Factors

    @Published var bestStrengthRatio: Double = 0
    @Published var bestFormQuality: Double = 0
    @Published var bestVelocityScore: Double = 0

    // MARK: - Promotion Series

    @Published var isInPromotionSeries: Bool = false
    @Published var promotionSeriesWins: Int = 0

    // MARK: - History

    @Published var rankHistory: [RankSnapshot] = []
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var totalWorkouts: Int = 0

    // MARK: - Dependencies

    private let context: NSManagedObjectContext
    private let leaderboardService: LeaderboardService
    let rankingEngine: RankingEngine

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        self.leaderboardService = LeaderboardService(context: context)
        self.rankingEngine = RankingEngine()
        loadData()
    }

    // MARK: - Load Data

    func loadData() {
        // Load current rank from profile
        if let rank = leaderboardService.fetchCurrentRank() {
            currentTier = rank.tier
            currentLP = rank.lp

            let progress = leaderboardService.lpProgress(
                currentLP: rank.lp,
                currentTier: rank.tier
            )
            lpInTier = progress.lpInTier
            lpToNextTier = progress.lpToNext
            lpProgress = progress.progress
        }

        // Load personal bests
        bestStrengthRatio = leaderboardService.fetchBestStrengthRatio()
        bestFormQuality = leaderboardService.fetchBestFormQuality()
        bestVelocityScore = leaderboardService.fetchBestVelocityScore()

        // Load history
        rankHistory = leaderboardService.fetchRankHistory(limit: 20)
        leaderboardEntries = leaderboardService.fetchPersonalLeaderboard(limit: 10)
        totalWorkouts = leaderboardService.totalWorkoutCount()
    }

    // MARK: - Record Workout

    /// Called by WorkoutViewModel after a session ends to record LP.
    func recordWorkout(
        sets: [(weight: Double, reps: Int, velocity: Double, formScore: Double)],
        bodyweight: Double,
        biologicalSex: String?
    ) {
        // Calculate LP
        let (workoutLP, _) = rankingEngine.calculateWorkoutLP(
            sets: sets,
            bodyweight: bodyweight,
            biologicalSex: biologicalSex
        )

        let newCumulativeLP = currentLP + workoutLP
        let newTier = rankingEngine.determineTier(totalLP: newCumulativeLP)

        // Process promotion series
        let promotion = rankingEngine.processPromotionSeries(
            workoutLP: workoutLP,
            currentTier: currentTier,
            cumulativeLP: newCumulativeLP
        )
        isInPromotionSeries = promotion.isInSeries
        promotionSeriesWins = promotion.seriesWins

        let effectiveTier = promotion.isPromoted ? (promotion.newTier ?? newTier) : currentTier

        // Compute workout averages for the snapshot
        let avgRatio = bodyweight > 0
            ? sets.map { $0.weight / bodyweight }.reduce(0, +) / max(1, Double(sets.count))
            : 0
        let avgForm = sets.map(\.formScore).reduce(0, +) / max(1, Double(sets.count))
        let avgVelocity = sets.map(\.velocity).reduce(0, +) / max(1, Double(sets.count))

        // Record to CoreData
        leaderboardService.recordWorkoutScore(
            workoutLP: workoutLP,
            strengthToWeightRatio: avgRatio,
            formQualityAverage: avgForm,
            velocityScore: avgVelocity,
            tier: effectiveTier
        )

        // Reload all data
        loadData()
    }
}
