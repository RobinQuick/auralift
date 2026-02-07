import Foundation
import CoreData

@objc(MorphoScan)
public class MorphoScan: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var scanDate: Date
    @NSManaged public var torsoLength: Double
    @NSManaged public var femurLength: Double
    @NSManaged public var tibiaLength: Double
    @NSManaged public var humerusLength: Double
    @NSManaged public var forearmLength: Double
    @NSManaged public var shoulderWidth: Double
    @NSManaged public var hipWidth: Double
    @NSManaged public var armSpan: Double
    @NSManaged public var femurToTorsoRatio: Double
    @NSManaged public var tibiaToFemurRatio: Double
    @NSManaged public var humerusToTorsoRatio: Double
    @NSManaged public var rawPoseData: Data?
    @NSManaged public var estimatedHeightCm: Double
    @NSManaged public var bodyFatEstimate: Double
    @NSManaged public var goldenRatioScore: Double
    @NSManaged public var waistEstimate: Double

    // MARK: - Relationships

    @NSManaged public var userProfile: NSManagedObject?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MorphoScan", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.scanDate = Date()
        self.torsoLength = 0.0
        self.femurLength = 0.0
        self.tibiaLength = 0.0
        self.humerusLength = 0.0
        self.forearmLength = 0.0
        self.shoulderWidth = 0.0
        self.hipWidth = 0.0
        self.armSpan = 0.0
        self.femurToTorsoRatio = 0.0
        self.tibiaToFemurRatio = 0.0
        self.humerusToTorsoRatio = 0.0
        self.estimatedHeightCm = 0.0
        self.bodyFatEstimate = 0.0
        self.goldenRatioScore = 0.0
        self.waistEstimate = 0.0
    }
}
