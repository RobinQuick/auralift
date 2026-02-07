import Foundation
import CoreData

@objc(GuildMembership)
public class GuildMembership: NSManagedObject {

    @NSManaged public var id: UUID
    @NSManaged public var guildName: String
    @NSManaged public var guildTag: String?
    @NSManaged public var joinDate: Date
    @NSManaged public var role: String?
    @NSManaged public var guildWarWins: Int32
    @NSManaged public var guildWarLosses: Int32

    // MARK: - Relationships
    @NSManaged public var userProfile: NSManagedObject?

    convenience init(context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: "GuildMembership", in: context)!
        self.init(entity: entity, insertInto: context)
        self.id = UUID()
        self.guildName = ""
        self.guildTag = nil
        self.joinDate = Date()
        self.role = nil
        self.guildWarWins = 0
        self.guildWarLosses = 0
    }
}
