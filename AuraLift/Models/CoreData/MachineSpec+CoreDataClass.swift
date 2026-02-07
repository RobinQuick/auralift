import Foundation
import CoreData

@objc(MachineSpec)
public class MachineSpec: NSManagedObject {

    // MARK: - Properties

    @NSManaged public var id: UUID
    @NSManaged public var machineName: String
    @NSManaged public var manufacturer: String?
    @NSManaged public var machineType: String?
    @NSManaged public var cablePositionHigh: Bool
    @NSManaged public var cablePositionMid: Bool
    @NSManaged public var cablePositionLow: Bool
    @NSManaged public var seatAdjustable: Bool
    @NSManaged public var padAdjustable: Bool
    @NSManaged public var weightStackMin: Double
    @NSManaged public var weightStackMax: Double
    @NSManaged public var weightIncrement: Double
    @NSManaged public var camProfileNotes: String?
    @NSManaged public var setupInstructions: String?
    @NSManaged public var resistanceProfile: String?   // "ascending", "descending", or "linear"
    @NSManaged public var startingResistance: Double    // Tare weight (empty lever arms) in kg

    // MARK: - Relationships

    @NSManaged public var exercise: NSManagedObject?

    // MARK: - Convenience Initializer

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "MachineSpec", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.machineName = ""
        self.cablePositionHigh = false
        self.cablePositionMid = false
        self.cablePositionLow = false
        self.seatAdjustable = false
        self.padAdjustable = false
        self.weightStackMin = 0.0
        self.weightStackMax = 0.0
        self.weightIncrement = 2.5
        self.resistanceProfile = "linear"
        self.startingResistance = 0.0
    }
}
