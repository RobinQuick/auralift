import Foundation
import CoreData
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var username: String = "Athlete"
    @Published var currentTier: RankTier = .iron
    @Published var currentLP: Int32 = 0
    @Published var totalXP: Int64 = 0
    @Published var todayVolume: Double = 0
    @Published var weeklyWorkouts: Int = 0
    @Published var overallReadiness: Double = 100

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadData()
    }

    func loadData() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1

        guard let profile = try? context.fetch(request).first else { return }

        username = (profile.value(forKey: "username") as? String) ?? "Athlete"
        let tierString = (profile.value(forKey: "currentRankTier") as? String) ?? "iron"
        currentTier = RankTier(rawValue: tierString) ?? .iron
        currentLP = (profile.value(forKey: "currentLP") as? Int32) ?? 0
        totalXP = (profile.value(forKey: "totalXP") as? Int64) ?? 0
    }
}
