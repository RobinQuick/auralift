import Foundation
import CoreData

// MARK: - ProgramExercise

/// A prescribed exercise within a ProgramDay, with targets and completion data.
@objc(ProgramExercise)
public class ProgramExercise: NSManagedObject {

    // MARK: - Attributes

    @NSManaged public var id: UUID
    @NSManaged public var exerciseOrder: Int16
    @NSManaged public var targetSets: Int16
    @NSManaged public var targetReps: String
    @NSManaged public var targetWeightKg: Double
    @NSManaged public var targetRPE: Double
    @NSManaged public var targetVelocityZone: String?
    @NSManaged public var restSeconds: Int16
    @NSManaged public var tempoDescription: String?
    @NSManaged public var whyMessage: String?
    @NSManaged public var priorityReason: String?
    @NSManaged public var isCompleted: Bool
    @NSManaged public var actualWeightKg: Double
    @NSManaged public var actualReps: Int16
    @NSManaged public var actualRPE: Double

    // MARK: - Relationships

    @NSManaged public var programDay: ProgramDay?
    @NSManaged public var exercise: Exercise?

    // MARK: - Convenience Init

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "ProgramExercise", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.exerciseOrder = 0
        self.targetSets = 3
        self.targetReps = "8-12"
        self.targetWeightKg = 0
        self.targetRPE = 7.0
        self.restSeconds = 90
        self.isCompleted = false
        self.actualWeightKg = 0
        self.actualReps = 0
        self.actualRPE = 0
    }

    // MARK: - Computed Helpers

    var exerciseName: String {
        exercise?.name ?? "Unknown"
    }

    var parsedVelocityZone: VelocityZone? {
        guard let zone = targetVelocityZone else { return nil }
        return VelocityZone(rawValue: zone)
    }

    var repRange: (min: Int, max: Int) {
        let parts = targetReps.components(separatedBy: "-")
        let min = Int(parts.first ?? "8") ?? 8
        let max = Int(parts.last ?? "12") ?? 12
        return (min, max)
    }
}
