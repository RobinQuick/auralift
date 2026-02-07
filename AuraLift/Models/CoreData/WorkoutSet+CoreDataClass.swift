import Foundation
import CoreData

@objc(WorkoutSet)
public class WorkoutSet: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var setNumber: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var weightKg: Double
    @NSManaged public var averageConcentricVelocity: Double
    @NSManaged public var peakConcentricVelocity: Double
    @NSManaged public var velocityLossPercent: Double
    @NSManaged public var autoStopped: Bool
    @NSManaged public var formScore: Double
    @NSManaged public var barPathDeviation: Double
    @NSManaged public var romDegrees: Double
    @NSManaged public var tempoActualConcentric: Double
    @NSManaged public var tempoActualEccentric: Double
    @NSManaged public var rpe: Double
    @NSManaged public var xpEarned: Int32
    @NSManaged public var comboTag: String?
    @NSManaged public var timestamp: Date?

    // MARK: - Relationships

    @NSManaged public var exercise: NSManagedObject?
    @NSManaged public var workoutSession: NSManagedObject?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "WorkoutSet", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.setNumber = 1
        self.reps = 0
        self.weightKg = 0.0
        self.averageConcentricVelocity = 0.0
        self.peakConcentricVelocity = 0.0
        self.velocityLossPercent = 0.0
        self.autoStopped = false
        self.formScore = 0.0
        self.barPathDeviation = 0.0
        self.romDegrees = 0.0
        self.tempoActualConcentric = 0.0
        self.tempoActualEccentric = 0.0
        self.rpe = 0.0
        self.xpEarned = 0
        self.timestamp = Date()
    }
}
