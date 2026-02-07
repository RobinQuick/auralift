import Foundation
import CoreData

@objc(NutritionLog)
public class NutritionLog: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var logDate: Date
    @NSManaged public var targetCalories: Double
    @NSManaged public var actualCalories: Double
    @NSManaged public var proteinGrams: Double
    @NSManaged public var carbsGrams: Double
    @NSManaged public var fatGrams: Double
    @NSManaged public var waterLiters: Double
    @NSManaged public var creatineGrams: Double
    @NSManaged public var wheyProteinGrams: Double

    // MARK: - Relationships
    @NSManaged public var userProfile: NSManagedObject?

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "NutritionLog", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.logDate = Date()
        self.targetCalories = 0.0
        self.actualCalories = 0.0
        self.proteinGrams = 0.0
        self.carbsGrams = 0.0
        self.fatGrams = 0.0
        self.waterLiters = 0.0
        self.creatineGrams = 0.0
        self.wheyProteinGrams = 0.0
    }
}
