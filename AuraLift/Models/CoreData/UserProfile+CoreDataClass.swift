import Foundation
import CoreData

@objc(UserProfile)
public class UserProfile: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var username: String
    @NSManaged public var email: String?
    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var biologicalSex: String?
    @NSManaged public var heightCm: Double
    @NSManaged public var weightKg: Double
    @NSManaged public var bodyFatPercentage: Double
    @NSManaged public var currentRankTier: String
    @NSManaged public var currentLP: Int32
    @NSManaged public var totalXP: Int64
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date

    // MARK: - Relationships

    @NSManaged public var morphoScans: NSSet?
    @NSManaged public var workoutSessions: NSSet?
    @NSManaged public var rankingRecords: NSSet?
    @NSManaged public var recoverySnapshots: NSSet?
    @NSManaged public var nutritionLogs: NSSet?
    @NSManaged public var guildMembership: NSManagedObject?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "UserProfile", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.username = ""
        self.heightCm = 0.0
        self.weightKg = 0.0
        self.bodyFatPercentage = 0.0
        self.currentRankTier = "Bronze"
        self.currentLP = 0
        self.totalXP = 0
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }
}
