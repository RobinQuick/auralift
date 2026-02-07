import Foundation
import CoreData

@objc(MuscleGroup)
public class MuscleGroup: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var bodyRegion: String?
    @NSManaged public var currentRecoveryScore: Double
    @NSManaged public var weeklyVolumeSets: Int16
    @NSManaged public var lastTrainedDate: Date?

    // MARK: - Relationships
    @NSManaged public var exercises: NSSet?
    @NSManaged public var recoverySnapshots: NSSet?

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MuscleGroup", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = ""
        self.bodyRegion = nil
        self.currentRecoveryScore = 0.0
        self.weeklyVolumeSets = 0
        self.lastTrainedDate = nil
    }
}
