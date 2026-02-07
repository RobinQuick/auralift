import Foundation
import CoreData

// MARK: - SeasonProgress

/// Tracks a user's progress through a seasonal battle pass.
/// Stores XP earned, current level, and which rewards have been claimed.
@objc(SeasonProgress)
public class SeasonProgress: NSManagedObject {

    // MARK: - Attributes

    @NSManaged public var id: UUID
    @NSManaged public var seasonId: String
    @NSManaged public var userXP: Int64
    @NSManaged public var currentLevel: Int16
    @NSManaged public var claimedRewards: String
    @NSManaged public var lastUpdated: Date

    // MARK: - Relationships

    @NSManaged public var userProfile: UserProfile?

    // MARK: - Convenience Init

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "SeasonProgress", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.seasonId = ""
        self.userXP = 0
        self.currentLevel = 1
        self.claimedRewards = ""
        self.lastUpdated = Date()
    }

    // MARK: - Computed Helpers

    /// Returns the list of claimed reward IDs as an array.
    var claimedRewardList: [String] {
        guard !claimedRewards.isEmpty else { return [] }
        return claimedRewards.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    /// Adds a reward ID to the claimed list.
    func markRewardClaimed(_ rewardId: String) {
        var list = claimedRewardList
        guard !list.contains(rewardId) else { return }
        list.append(rewardId)
        claimedRewards = list.joined(separator: ",")
        lastUpdated = Date()
    }
}
