import Foundation
import CoreData

@objc(RecoverySnapshot)
public class RecoverySnapshot: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var snapshotDate: Date
    @NSManaged public var hrvValue: Double
    @NSManaged public var sleepHours: Double
    @NSManaged public var sleepQualityScore: Double
    @NSManaged public var restingHeartRate: Double
    @NSManaged public var activeEnergyBurned: Double
    @NSManaged public var cyclePhase: String?
    @NSManaged public var overallReadiness: Double

    // MARK: - Relationships
    @NSManaged public var userProfile: NSManagedObject?
    @NSManaged public var muscleGroup: NSManagedObject?

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "RecoverySnapshot", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.snapshotDate = Date()
        self.hrvValue = 0.0
        self.sleepHours = 0.0
        self.sleepQualityScore = 0.0
        self.restingHeartRate = 0.0
        self.activeEnergyBurned = 0.0
        self.cyclePhase = nil
        self.overallReadiness = 0.0
    }
}
