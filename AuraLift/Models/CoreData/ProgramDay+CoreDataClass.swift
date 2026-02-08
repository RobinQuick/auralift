import Foundation
import CoreData

// MARK: - ProgramDay

/// A single day within a ProgramWeek, containing the scheduled exercises.
@objc(ProgramDay)
public class ProgramDay: NSManagedObject {

    // MARK: - Attributes

    @NSManaged public var id: UUID
    @NSManaged public var dayIndex: Int16
    @NSManaged public var dayLabel: String
    @NSManaged public var scheduledDate: Date?
    @NSManaged public var isRestDay: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var completedSessionId: UUID?
    @NSManaged public var estimatedDurationMinutes: Int16
    @NSManaged public var recoveryFocus: String?

    // MARK: - Relationships

    @NSManaged public var programWeek: ProgramWeek?
    @NSManaged public var exercises: NSOrderedSet?

    // MARK: - Convenience Init

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "ProgramDay", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.dayIndex = 0
        self.dayLabel = ""
        self.isRestDay = false
        self.isCompleted = false
        self.estimatedDurationMinutes = 0
    }

    // MARK: - Computed Helpers

    var sortedExercises: [ProgramExercise] {
        guard let ordered = exercises else { return [] }
        return ordered.array.compactMap { $0 as? ProgramExercise }
            .sorted { $0.exerciseOrder < $1.exerciseOrder }
    }

    var exerciseCount: Int {
        sortedExercises.count
    }

    var completedExerciseCount: Int {
        sortedExercises.filter(\.isCompleted).count
    }
}
