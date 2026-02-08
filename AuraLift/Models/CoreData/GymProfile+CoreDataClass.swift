import Foundation
import CoreData

// MARK: - GymProfile

/// Represents a user's gym with its available equipment and machine brands.
@objc(GymProfile)
public class GymProfile: NSManagedObject {

    // MARK: - Attributes

    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var availableEquipment: String
    @NSManaged public var availableBrands: String
    @NSManaged public var isActive: Bool

    // MARK: - Relationships

    @NSManaged public var userProfile: UserProfile?
    @NSManaged public var trainingPrograms: NSSet?

    // MARK: - Convenience Init

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "GymProfile", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.name = ""
        self.availableEquipment = ""
        self.availableBrands = ""
        self.isActive = true
    }

    // MARK: - Computed Helpers

    var equipmentList: [String] {
        guard !availableEquipment.isEmpty else { return [] }
        return availableEquipment.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    var brandList: [String] {
        guard !availableBrands.isEmpty else { return [] }
        return availableBrands.components(separatedBy: ",").filter { !$0.isEmpty }
    }

    func hasEquipment(_ type: String) -> Bool {
        equipmentList.contains(type)
    }

    func hasBrand(_ brand: String) -> Bool {
        brandList.contains(brand)
    }
}
