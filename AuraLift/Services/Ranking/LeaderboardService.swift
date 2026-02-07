import Foundation
import CoreData

// MARK: - PersonalBest

/// A personal best record for a specific metric.
struct PersonalBest {
    let exerciseName: String
    let value: Double
    let date: Date
}

// MARK: - RankSnapshot

/// A snapshot of the user's ranking state at a point in time.
struct RankSnapshot {
    let date: Date
    let tier: RankTier
    let lp: Int32
    let strengthToWeightRatio: Double
    let formQualityAverage: Double
    let velocityScore: Double
}

// MARK: - LeaderboardEntry

/// A single entry in the leaderboard (local personal history).
struct LeaderboardEntry: Identifiable {
    let id: UUID
    let rank: Int
    let date: Date
    let tier: RankTier
    let lp: Int32
    let isCurrentSession: Bool
}

// MARK: - LeaderboardService

/// Manages local ranking data: personal bests, ranking history, and LP tracking.
/// Local-first architecture — no backend sync in v1.
final class LeaderboardService: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Record Workout Score

    /// Records a workout's LP to the user's profile and creates a ranking snapshot.
    ///
    /// - Parameters:
    ///   - workoutLP: LP earned in this workout.
    ///   - strengthToWeightRatio: Average strength-to-weight ratio across sets.
    ///   - formQualityAverage: Average form score (0–100) across sets.
    ///   - velocityScore: Average mean concentric velocity (m/s) across sets.
    ///   - tier: The user's tier after this workout.
    func recordWorkoutScore(
        workoutLP: Int32,
        strengthToWeightRatio: Double,
        formQualityAverage: Double,
        velocityScore: Double,
        tier: RankTier
    ) {
        // Update user profile
        guard let profile = fetchUserProfile() else { return }

        let newTotalLP = profile.currentLP + workoutLP
        profile.currentLP = newTotalLP
        profile.currentRankTier = tier.rawValue
        profile.updatedAt = Date()

        // Create ranking record snapshot
        let record = RankingRecord(context: context)
        record.id = UUID()
        record.recordDate = Date()
        record.tier = tier.rawValue
        record.lpAtRecord = newTotalLP
        record.strengthToWeightRatio = strengthToWeightRatio
        record.formQualityAverage = formQualityAverage
        record.velocityScore = velocityScore
        record.userProfile = profile

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - User Profile

    /// Fetches the current user's profile.
    func fetchUserProfile() -> UserProfile? {
        let request = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    /// Returns the user's current LP and tier.
    func fetchCurrentRank() -> (tier: RankTier, lp: Int32)? {
        guard let profile = fetchUserProfile() else { return nil }
        let tier = RankTier(rawValue: profile.currentRankTier) ?? .iron
        return (tier, profile.currentLP)
    }

    // MARK: - Ranking History

    /// Fetches the user's ranking history ordered by date.
    func fetchRankHistory(limit: Int = 20) -> [RankSnapshot] {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "recordDate", ascending: false)]
        request.fetchLimit = limit

        guard let records = try? context.fetch(request) else { return [] }

        return records.compactMap { record in
            guard let tierString = record.tier,
                  let tier = RankTier(rawValue: tierString) else { return nil }

            return RankSnapshot(
                date: record.recordDate,
                tier: tier,
                lp: record.lpAtRecord,
                strengthToWeightRatio: record.strengthToWeightRatio,
                formQualityAverage: record.formQualityAverage,
                velocityScore: record.velocityScore
            )
        }
    }

    // MARK: - Personal Best Tracking

    /// Returns the user's best strength-to-weight ratio across all workouts.
    func fetchBestStrengthRatio() -> Double {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "strengthToWeightRatio", ascending: false)]
        request.fetchLimit = 1

        guard let record = try? context.fetch(request).first else { return 0 }
        return record.strengthToWeightRatio
    }

    /// Returns the user's best form quality average across all workouts.
    func fetchBestFormQuality() -> Double {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "formQualityAverage", ascending: false)]
        request.fetchLimit = 1

        guard let record = try? context.fetch(request).first else { return 0 }
        return record.formQualityAverage
    }

    /// Returns the user's best velocity score across all workouts.
    func fetchBestVelocityScore() -> Double {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "velocityScore", ascending: false)]
        request.fetchLimit = 1

        guard let record = try? context.fetch(request).first else { return 0 }
        return record.velocityScore
    }

    /// Returns the highest LP the user has ever reached.
    func fetchPeakLP() -> Int32 {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        request.sortDescriptors = [NSSortDescriptor(key: "lpAtRecord", ascending: false)]
        request.fetchLimit = 1

        guard let record = try? context.fetch(request).first else { return 0 }
        return record.lpAtRecord
    }

    // MARK: - Leaderboard (Personal History)

    /// Generates a leaderboard from the user's workout history,
    /// ranked by LP earned per session (highest first).
    func fetchPersonalLeaderboard(limit: Int = 10) -> [LeaderboardEntry] {
        let history = fetchRankHistory(limit: limit)

        // Sort by LP descending for ranking
        let sorted = history.sorted { $0.lp > $1.lp }

        return sorted.enumerated().map { index, snapshot in
            LeaderboardEntry(
                id: UUID(),
                rank: index + 1,
                date: snapshot.date,
                tier: snapshot.tier,
                lp: snapshot.lp,
                isCurrentSession: index == 0 && snapshot.date.timeIntervalSinceNow > -3600
            )
        }
    }

    // MARK: - LP Progress

    /// Calculates LP progress toward the next tier.
    func lpProgress(currentLP: Int32, currentTier: RankTier) -> (lpInTier: Int32, lpToNext: Int32, progress: Double) {
        guard let nextTier = currentTier.nextTier else {
            return (currentLP - currentTier.lpThreshold, 0, 1.0)
        }

        let tierRange = nextTier.lpThreshold - currentTier.lpThreshold
        let lpInTier = currentLP - currentTier.lpThreshold
        let progress = tierRange > 0 ? Double(lpInTier) / Double(tierRange) : 1.0

        return (lpInTier, tierRange, min(1.0, max(0.0, progress)))
    }

    // MARK: - Workout Count

    /// Returns the total number of recorded workouts.
    func totalWorkoutCount() -> Int {
        let request = NSFetchRequest<RankingRecord>(entityName: "RankingRecord")
        return (try? context.count(for: request)) ?? 0
    }
}
