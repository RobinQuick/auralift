import Foundation
import CoreData

@objc(ScienceInsight)
public class ScienceInsight: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var fetchDate: Date
    @NSManaged public var topic: String?
    @NSManaged public var source: String?
    @NSManaged public var summary: String?
    @NSManaged public var recommendedTempoChange: String?
    @NSManaged public var recommendedRestChange: String?
    @NSManaged public var appliedToExercises: String?
    @NSManaged public var isActive: Bool

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "ScienceInsight", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.fetchDate = Date()
        self.topic = nil
        self.source = nil
        self.summary = nil
        self.recommendedTempoChange = nil
        self.recommendedRestChange = nil
        self.appliedToExercises = nil
        self.isActive = true
    }
}
