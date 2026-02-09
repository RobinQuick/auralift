import Foundation
import CoreData
import UserNotifications

// MARK: - DailyQuest

/// A single daily quest (Cyber-Op) with objective, progress tracking, and XP reward.
struct DailyQuest: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let targetValue: Double
    var currentValue: Double
    let xpReward: Int64
    let questType: QuestType

    var isCompleted: Bool {
        currentValue >= targetValue
    }

    var progressPercent: Double {
        guard targetValue > 0 else { return 0 }
        return min(1.0, currentValue / targetValue)
    }

    enum QuestType: String, Codable {
        case logWorkout        // Complete N workouts
        case totalVolume       // Accumulate N kg volume
        case formScore         // Achieve avg form score >= N
        case totalReps         // Complete N reps total
        case streakDay         // Maintain streak (auto-complete if streak active)
        case shareToGuild      // Share a workout to guild
        case velocityTarget    // Hit peak velocity >= N m/s
        case completeNSets     // Complete N sets
    }
}

// MARK: - Quest Templates

/// Pool of quest templates from which 3 are randomly selected each day.
private struct QuestTemplate {
    let titleFormat: String
    let descriptionFormat: String
    let iconName: String
    let questType: DailyQuest.QuestType
    let targetRange: ClosedRange<Double>
    let xpReward: Int64

    func generate(seed: Int) -> DailyQuest {
        let step: Double
        switch questType {
        case .totalVolume: step = 500
        case .formScore: step = 5
        case .velocityTarget: step = 0.05
        default: step = 1
        }

        let range = targetRange.upperBound - targetRange.lowerBound
        let value = targetRange.lowerBound + (Double(seed % Int(max(1, range / step))) * step)
        let target = max(targetRange.lowerBound, min(targetRange.upperBound, value))

        let title: String
        let description: String
        switch questType {
        case .totalVolume:
            title = String(format: titleFormat, Int(target))
            description = String(format: descriptionFormat, Int(target))
        case .formScore:
            title = String(format: titleFormat, Int(target))
            description = String(format: descriptionFormat, Int(target))
        case .velocityTarget:
            title = String(format: titleFormat, target)
            description = String(format: descriptionFormat, target)
        default:
            title = String(format: titleFormat, Int(target))
            description = String(format: descriptionFormat, Int(target))
        }

        return DailyQuest(
            id: UUID().uuidString,
            title: title,
            description: description,
            iconName: iconName,
            targetValue: target,
            currentValue: 0,
            xpReward: xpReward,
            questType: questType
        )
    }
}

// MARK: - DailyQuestManager

/// Generates 3 random daily quests at midnight, tracks progress,
/// and schedules local notification at 09:00.
@MainActor
final class DailyQuestManager: ObservableObject {

    // MARK: - Singleton

    static let shared = DailyQuestManager()

    // MARK: - UserDefaults Keys

    private static let questsKey = "com.aurea.dailyQuests"
    private static let questDateKey = "com.aurea.dailyQuestsDate"

    // MARK: - Published State

    @Published var quests: [DailyQuest] = []
    @Published var allCompleted: Bool = false

    // MARK: - Quest Pool

    private let templates: [QuestTemplate] = [
        QuestTemplate(
            titleFormat: "Log %d Workout",
            descriptionFormat: "Complète %d entraînement(s) aujourd'hui",
            iconName: "dumbbell.fill",
            questType: .logWorkout,
            targetRange: 1...2,
            xpReward: 150
        ),
        QuestTemplate(
            titleFormat: "Volume > %d kg",
            descriptionFormat: "Accumule %d kg de volume total",
            iconName: "scalemass.fill",
            questType: .totalVolume,
            targetRange: 2000...8000,
            xpReward: 200
        ),
        QuestTemplate(
            titleFormat: "Form Score ≥ %d%%",
            descriptionFormat: "Maintiens un score de forme moyen ≥ %d%%",
            iconName: "checkmark.seal.fill",
            questType: .formScore,
            targetRange: 75...95,
            xpReward: 175
        ),
        QuestTemplate(
            titleFormat: "%d Reps Total",
            descriptionFormat: "Complète %d répétitions au total",
            iconName: "repeat",
            questType: .totalReps,
            targetRange: 30...100,
            xpReward: 150
        ),
        QuestTemplate(
            titleFormat: "Streak Actif",
            descriptionFormat: "Maintiens ton streak en étant actif aujourd'hui",
            iconName: "flame.fill",
            questType: .streakDay,
            targetRange: 1...1,
            xpReward: 100
        ),
        QuestTemplate(
            titleFormat: "Partage Guild",
            descriptionFormat: "Partage un résultat avec ta guild",
            iconName: "person.3.fill",
            questType: .shareToGuild,
            targetRange: 1...1,
            xpReward: 125
        ),
        QuestTemplate(
            titleFormat: "Vélocité ≥ %.2f m/s",
            descriptionFormat: "Atteins un pic de vélocité ≥ %.2f m/s",
            iconName: "speedometer",
            questType: .velocityTarget,
            targetRange: 0.50...0.90,
            xpReward: 200
        ),
        QuestTemplate(
            titleFormat: "%d Sets Complétés",
            descriptionFormat: "Complète %d sets dans ta session",
            iconName: "list.bullet.rectangle.fill",
            questType: .completeNSets,
            targetRange: 3...8,
            xpReward: 150
        ),
    ]

    // MARK: - Init

    private init() {
        loadOrGenerateQuests()
        scheduleNotification()
    }

    // MARK: - Load / Generate

    func loadOrGenerateQuests() {
        let defaults = UserDefaults.standard
        let storedDate = defaults.string(forKey: Self.questDateKey) ?? ""
        let todayKey = todayDateKey()

        if storedDate == todayKey,
           let data = defaults.data(forKey: Self.questsKey),
           let decoded = try? JSONDecoder().decode([DailyQuest].self, from: data) {
            quests = decoded
        } else {
            generateNewQuests()
        }

        allCompleted = quests.allSatisfy(\.isCompleted)
    }

    private func generateNewQuests() {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        var seeds = Array(0..<templates.count)

        // Deterministic shuffle based on day
        var rng = seeds
        for i in stride(from: rng.count - 1, through: 1, by: -1) {
            let j = (dayOfYear * (i + 7)) % (i + 1)
            rng.swapAt(i, j)
        }

        // Pick 3 unique quest types
        var selected: [DailyQuest] = []
        var usedTypes = Set<DailyQuest.QuestType>()

        for idx in rng {
            guard selected.count < 3 else { break }
            let template = templates[idx]
            guard !usedTypes.contains(template.questType) else { continue }
            usedTypes.insert(template.questType)
            selected.append(template.generate(seed: dayOfYear + idx))
        }

        quests = selected
        saveQuests()
    }

    // MARK: - Progress Updates

    /// Called when a workout session ends with aggregate stats.
    func recordWorkoutCompletion(
        totalVolume: Double,
        avgFormScore: Double,
        totalReps: Int,
        peakVelocity: Double,
        totalSets: Int,
        context: NSManagedObjectContext
    ) {
        for i in quests.indices {
            switch quests[i].questType {
            case .logWorkout:
                quests[i].currentValue += 1
            case .totalVolume:
                quests[i].currentValue += totalVolume
            case .formScore:
                quests[i].currentValue = max(quests[i].currentValue, avgFormScore)
            case .totalReps:
                quests[i].currentValue += Double(totalReps)
            case .streakDay:
                if CyberStreakManager.shared.currentStreak > 0 {
                    quests[i].currentValue = 1
                }
            case .velocityTarget:
                quests[i].currentValue = max(quests[i].currentValue, peakVelocity)
            case .completeNSets:
                quests[i].currentValue += Double(totalSets)
            case .shareToGuild:
                break // Updated separately via recordGuildShare()
            }
        }

        // Award XP for newly completed quests
        for quest in quests where quest.isCompleted {
            let wasAlreadyClaimed = questWasPreviouslyComplete(quest.id)
            if !wasAlreadyClaimed {
                SeasonEngine.shared.addXP(quest.xpReward, context: context)
            }
        }

        allCompleted = quests.allSatisfy(\.isCompleted)
        saveQuests()
    }

    /// Call when user shares to guild.
    func recordGuildShare(context: NSManagedObjectContext) {
        for i in quests.indices where quests[i].questType == .shareToGuild {
            quests[i].currentValue = 1
            if quests[i].isCompleted {
                SeasonEngine.shared.addXP(quests[i].xpReward, context: context)
            }
        }
        allCompleted = quests.allSatisfy(\.isCompleted)
        saveQuests()
    }

    // MARK: - Total XP Available

    var totalQuestXP: Int64 {
        quests.reduce(0) { $0 + $1.xpReward }
    }

    var completedQuestCount: Int {
        quests.filter(\.isCompleted).count
    }

    // MARK: - Notifications

    private func scheduleNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = "CYBER-OPS DISPONIBLES"
            content.body = "Vos 3 nouvelles missions quotidiennes vous attendent. Gagnez jusqu'à \(self.totalQuestXP) XP !"
            content.sound = .default

            // Schedule for 09:00 daily
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "com.aurea.dailyOps",
                content: content,
                trigger: trigger
            )

            center.removePendingNotificationRequests(withIdentifiers: ["com.aurea.dailyOps"])
            center.add(request)
        }
    }

    // MARK: - Persistence

    private func saveQuests() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(quests) {
            defaults.set(data, forKey: Self.questsKey)
        }
        defaults.set(todayDateKey(), forKey: Self.questDateKey)
    }

    private func todayDateKey() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func questWasPreviouslyComplete(_ questId: String) -> Bool {
        // Check if quest was already saved as complete before this update
        guard let data = UserDefaults.standard.data(forKey: Self.questsKey),
              let previous = try? JSONDecoder().decode([DailyQuest].self, from: data),
              let prevQuest = previous.first(where: { $0.id == questId }) else {
            return false
        }
        return prevQuest.isCompleted
    }

    // MARK: - Reset

    func reset() {
        quests = []
        allCompleted = false
        UserDefaults.standard.removeObject(forKey: Self.questsKey)
        UserDefaults.standard.removeObject(forKey: Self.questDateKey)
    }
}
