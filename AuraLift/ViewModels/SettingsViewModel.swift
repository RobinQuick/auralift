import Foundation
import CoreData

/// Handles account deletion: wipes all CoreData entities and resets UserDefaults.
@MainActor
final class SettingsViewModel: ObservableObject {

    // MARK: - Published State

    @Published var showDeleteConfirmation = false
    @Published var isDeleting = false
    @Published var deleteComplete = false

    // MARK: - Dependencies

    private let context: NSManagedObjectContext

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Account Deletion

    func deleteAccount() {
        isDeleting = true

        // Delete all CoreData entities (children before parents)
        let entityNames = [
            "WorkoutSet",
            "WorkoutSession",
            "RankingRecord",
            "MorphoScan",
            "RecoverySnapshot",
            "NutritionLog",
            "ScienceInsight",
            "GuildMembership",
            "SeasonProgress",
            "MachineSpec",
            "Exercise",
            "MuscleGroup",
            "UserProfile"
        ]

        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: entityName)
            do {
                let objects = try context.fetch(fetchRequest)
                for object in objects {
                    context.delete(object)
                }
            } catch {
                // Entity may not exist yet — continue
            }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
            isDeleting = false
            return
        }

        // Reset all UserDefaults flags
        let userDefaultsKeys = [
            "com.auralift.seedDataLoaded",
            "com.auralift.machineSeedDataLoaded",
            "com.auralift.privacyConsentAccepted",
            "audio.masterVolume",
            "audio.voiceVolume",
            "audio.sfxVolume",
            "audio.voiceEnabled",
            "audio.sfxEnabled",
            "audio.hapticsEnabled",
            "announcer.voicePack",
            "com.auralift.seasonInitialized",
            "com.auralift.streak.count",
            "com.auralift.streak.lastActiveDate",
            "com.auralift.dailyQuests",
            "com.auralift.dailyQuestsDate"
        ]

        for key in userDefaultsKeys {
            UserDefaults.standard.removeObject(forKey: key)
        }

        // Reset streak and daily quests
        CyberStreakManager.shared.reset()
        DailyQuestManager.shared.reset()

        // Note: HealthKit permissions cannot be revoked programmatically.
        // Users must go to Settings → Health → AuraLift to remove access.

        isDeleting = false
        deleteComplete = true
    }
}
