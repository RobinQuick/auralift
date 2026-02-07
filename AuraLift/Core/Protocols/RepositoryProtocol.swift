import Foundation
import CoreData

/// Generic data access interface for CoreData entities.
protocol RepositoryProtocol {
    associatedtype Entity: NSManagedObject

    var context: NSManagedObjectContext { get }

    func fetchAll() throws -> [Entity]
    func fetch(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?) throws -> [Entity]
    func fetchById(_ id: UUID) throws -> Entity?
    func create() -> Entity
    func delete(_ entity: Entity) throws
    func save() throws
}

extension RepositoryProtocol {
    func fetchAll() throws -> [Entity] {
        try fetch(predicate: nil, sortDescriptors: nil)
    }

    func fetch(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Entity] {
        let request = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        return try context.fetch(request)
    }

    func fetchById(_ id: UUID) throws -> Entity? {
        let request = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    func create() -> Entity {
        Entity(context: context)
    }

    func delete(_ entity: Entity) throws {
        context.delete(entity)
        try save()
    }

    func save() throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}
