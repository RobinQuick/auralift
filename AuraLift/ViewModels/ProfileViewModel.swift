import Foundation
import CoreData
import SwiftUI

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var username: String = "Athlete"
    @Published var email: String = ""
    @Published var heightCm: Double = 0
    @Published var weightKg: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var biologicalSex: String = "other"
    @Published var currentTier: RankTier = .iron
    @Published var totalXP: Int64 = 0
    @Published var totalWorkouts: Int = 0
    @Published var memberSince: Date = Date()

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        loadProfile()
    }

    func loadProfile() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1

        guard let profile = try? context.fetch(request).first else { return }

        username = (profile.value(forKey: "username") as? String) ?? "Athlete"
        email = (profile.value(forKey: "email") as? String) ?? ""
        heightCm = (profile.value(forKey: "heightCm") as? Double) ?? 0
        weightKg = (profile.value(forKey: "weightKg") as? Double) ?? 0
        bodyFatPercentage = (profile.value(forKey: "bodyFatPercentage") as? Double) ?? 0
        biologicalSex = (profile.value(forKey: "biologicalSex") as? String) ?? "other"
        let tierString = (profile.value(forKey: "currentRankTier") as? String) ?? "iron"
        currentTier = RankTier(rawValue: tierString) ?? .iron
        totalXP = (profile.value(forKey: "totalXP") as? Int64) ?? 0
        memberSince = (profile.value(forKey: "createdAt") as? Date) ?? Date()

        // Count workout sessions
        if let sessions = profile.value(forKey: "workoutSessions") as? NSSet {
            totalWorkouts = sessions.count
        }
    }

    func updateProfile(username: String, heightCm: Double, weightKg: Double) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1

        guard let profile = try? context.fetch(request).first else { return }

        profile.setValue(username, forKey: "username")
        profile.setValue(heightCm, forKey: "heightCm")
        profile.setValue(weightKg, forKey: "weightKg")
        profile.setValue(Date(), forKey: "updatedAt")

        try? context.save()
        loadProfile()
    }
}
