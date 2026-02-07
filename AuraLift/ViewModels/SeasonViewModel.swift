import Foundation
import CoreData
import Combine

// MARK: - SeasonViewModel

/// Drives the Season Pass UI: loads progress, computes display state,
/// and handles reward claiming.
@MainActor
final class SeasonViewModel: ObservableObject {

    // MARK: - Published State

    @Published var season: Season?
    @Published var currentLevel: Int = 1
    @Published var totalXP: Int64 = 0
    @Published var progressPercent: Double = 0
    @Published var progressCurrent: Int64 = 0
    @Published var progressRequired: Int64 = 1
    @Published var claimedRewards: Set<String> = []
    @Published var isPro: Bool = false

    // MARK: - Dependencies

    private let seasonEngine = SeasonEngine.shared
    private let premiumManager = PremiumManager.shared
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context

        premiumManager.$isPro
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pro in
                self?.isPro = pro
            }
            .store(in: &cancellables)
    }

    // MARK: - Load

    func loadSeasonData() {
        season = seasonEngine.currentSeason

        guard let progress = seasonEngine.fetchOrCreateProgress(context: context) else { return }

        currentLevel = Int(progress.currentLevel)
        totalXP = progress.userXP
        claimedRewards = Set(progress.claimedRewardList)
        isPro = premiumManager.isPro

        let (current, required) = seasonEngine.getProgressToNextLevel(progress: progress)
        progressCurrent = current
        progressRequired = required
        progressPercent = required > 0 ? min(1.0, Double(current) / Double(required)) : 1.0
    }

    // MARK: - Reward Management

    func canClaimReward(_ reward: SeasonReward, level: SeasonLevel, isPremiumTrack: Bool) -> Bool {
        guard !claimedRewards.contains(reward.id) else { return false }
        guard currentLevel >= level.level else { return false }
        if isPremiumTrack && !isPro { return false }
        return true
    }

    func isRewardClaimed(_ rewardId: String) -> Bool {
        claimedRewards.contains(rewardId)
    }

    func claimReward(_ reward: SeasonReward) {
        let success = seasonEngine.claimReward(reward.id, isPro: isPro, context: context)
        if success {
            claimedRewards.insert(reward.id)
        }
    }

    // MARK: - Season Info

    var seasonName: String {
        season?.name ?? "ALPHA PROTOCOL"
    }

    var seasonEndDate: String {
        guard let end = season?.endDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: end)
    }

    var daysRemaining: Int {
        guard let end = season?.endDate else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(0, days)
    }

    var levels: [SeasonLevel] {
        season?.levels ?? []
    }
}
