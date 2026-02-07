import Foundation
import CoreData

@objc(WorkoutSession)
public class WorkoutSession: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var totalVolume: Double
    @NSManaged public var totalXPEarned: Int32
    @NSManaged public var lpChange: Int32
    @NSManaged public var averageFormScore: Double
    @NSManaged public var comboMultiplier: Double
    @NSManaged public var peakVelocity: Double
    @NSManaged public var sessionNotes: String?

    // MARK: - Relationships

    @NSManaged public var userProfile: NSManagedObject?
    @NSManaged public var workoutSets: NSOrderedSet?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "WorkoutSession", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.startTime = Date()
        self.totalVolume = 0.0
        self.totalXPEarned = 0
        self.lpChange = 0
        self.averageFormScore = 0.0
        self.comboMultiplier = 1.0
        self.peakVelocity = 0.0
    }
}
