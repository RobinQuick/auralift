import Foundation
import CoreData

// MARK: - ProgramWeek

/// One week within a TrainingProgram, carrying periodization metadata.
@objc(ProgramWeek)
public class ProgramWeek: NSManagedObject {

    // MARK: - Attributes

    @NSManaged public var id: UUID
    @NSManaged public var weekNumber: Int16
    @NSManaged public var weekType: String
    @NSManaged public var volumeModifier: Double
    @NSManaged public var intensityModifier: Double
    @NSManaged public var overloadNotes: String?
    @NSManaged public var isComplete: Bool

    // MARK: - Relationships

    @NSManaged public var trainingProgram: TrainingProgram?
    @NSManaged public var days: NSOrderedSet?

    // MARK: - Convenience Init

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "ProgramWeek", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.weekNumber = 1
        self.weekType = ProgramWeekType.normal.rawValue
        self.volumeModifier = 1.0
        self.intensityModifier = 1.0
        self.isComplete = false
    }

    // MARK: - Computed Helpers

    var parsedWeekType: ProgramWeekType {
        ProgramWeekType(rawValue: weekType) ?? .normal
    }

    var sortedDays: [ProgramDay] {
        guard let ordered = days else { return [] }
        return ordered.array.compactMap { $0 as? ProgramDay }
            .sorted { $0.dayIndex < $1.dayIndex }
    }

    var trainingDays: [ProgramDay] {
        sortedDays.filter { !$0.isRestDay }
    }

    var completedDayCount: Int {
        sortedDays.filter(\.isCompleted).count
    }
}
