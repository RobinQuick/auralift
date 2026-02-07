import Foundation
import CoreData

@objc(RankingRecord)
public class RankingRecord: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var recordDate: Date
    @NSManaged public var tier: String?
    @NSManaged public var lpAtRecord: Int32
    @NSManaged public var strengthToWeightRatio: Double
    @NSManaged public var formQualityAverage: Double
    @NSManaged public var velocityScore: Double

    // MARK: - Relationships
    @NSManaged public var userProfile: NSManagedObject?

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "RankingRecord", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.recordDate = Date()
        self.tier = nil
        self.lpAtRecord = 0
        self.strengthToWeightRatio = 0.0
        self.formQualityAverage = 0.0
        self.velocityScore = 0.0
    }
}
