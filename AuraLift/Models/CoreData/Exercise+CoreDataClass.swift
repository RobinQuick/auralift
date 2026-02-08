import Foundation
import CoreData

@objc(Exercise)
public class Exercise: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var category: String?
    @NSManaged public var primaryMuscle: String?
    @NSManaged public var secondaryMuscles: String?
    @NSManaged public var equipmentType: String?
    @NSManaged public var defaultTempoConcentric: Double
    @NSManaged public var defaultTempoEccentric: Double
    @NSManaged public var defaultTempoPause: Double
    @NSManaged public var biomechanicalNotes: String?
    @NSManaged public var stretchPositionBonus: Bool
    @NSManaged public var riskLevel: String?
    @NSManaged public var isCustom: Bool

    // MARK: - Relationships

    @NSManaged public var machineSpec: NSManagedObject?
    @NSManaged public var workoutSets: NSSet?
    @NSManaged public var muscleGroups: NSSet?
    @NSManaged public var programExercises: NSSet?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "Exercise", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = ""
        self.defaultTempoConcentric = 1.0
        self.defaultTempoEccentric = 2.0
        self.defaultTempoPause = 0.5
        self.stretchPositionBonus = false
        self.isCustom = false
    }
}
