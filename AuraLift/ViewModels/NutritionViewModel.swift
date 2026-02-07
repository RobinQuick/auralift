import Foundation
import CoreData
import SwiftUI

@MainActor
class NutritionViewModel: ObservableObject {

    // MARK: - Published State

    // Macro targets
    @Published var macroTargets: MacroTargets?
    @Published var targetCalories: Double = 2500
    @Published var targetProtein: Double = 180
    @Published var targetCarbs: Double = 280
    @Published var targetFat: Double = 75
    @Published var targetWater: Double = 3.0

    // Actual intake (from log)
    @Published var actualCalories: Double = 0
    @Published var actualProtein: Double = 0
    @Published var actualCarbs: Double = 0
    @Published var actualFat: Double = 0
    @Published var actualWater: Double = 0

    // Body composition
    @Published var bodyFatPercent: Double = 0
    @Published var weightKg: Double = 0
    @Published var heightCm: Double = 0
    @Published var leanMassKg: Double = 0

    // Goal & plan
    @Published var currentGoal: NutritionGoal = .maintenance
    @Published var trainingDay: TrainingDayType = .rest
    @Published var nutritionPlan: NutritionPlan?

    // Golden Ratio
    @Published var goldenRatioResult: GoldenRatioResult?

    // Supplements
    @Published var supplements: [SupplementRecommendation] = []

    // UI
    @Published var isLoading: Bool = false

    // MARK: - Services

    private let nutritionService = NutritionService()
    private let supplementAdvisor = SupplementAdvisor()
    private let morphoScanner = MorphoScannerService()
    private let context: NSManagedObjectContext

    // MARK: - Computed

    var calorieProgress: Double {
        guard targetCalories > 0 else { return 0 }
        return min(actualCalories / targetCalories, 1.5)
    }

    var proteinProgress: Double {
        guard targetProtein > 0 else { return 0 }
        return min(actualProtein / targetProtein, 1.5)
    }

    var carbsProgress: Double {
        guard targetCarbs > 0 else { return 0 }
        return min(actualCarbs / targetCarbs, 1.5)
    }

    var fatProgress: Double {
        guard targetFat > 0 else { return 0 }
        return min(actualFat / targetFat, 1.5)
    }

    var waterProgress: Double {
        guard targetWater > 0 else { return 0 }
        return min(actualWater / targetWater, 1.5)
    }

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
        loadUserProfile()
        loadTodayLog()
        computeTargets()
    }

    // MARK: - Load User Data

    private func loadUserProfile() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1

        guard let profile = try? context.fetch(request).first else { return }

        weightKg = (profile.value(forKey: "weightKg") as? Double) ?? 0
        heightCm = (profile.value(forKey: "heightCm") as? Double) ?? 0
        bodyFatPercent = (profile.value(forKey: "bodyFatPercentage") as? Double) ?? 0

        if bodyFatPercent > 0 && weightKg > 0 {
            leanMassKg = weightKg * (1.0 - bodyFatPercent / 100.0)
        }
    }

    func loadTodayLog() {
        let request = NSFetchRequest<NSManagedObject>(entityName: "NutritionLog")
        let today = Calendar.current.startOfDay(for: Date())
        request.predicate = NSPredicate(format: "logDate >= %@", today as NSDate)
        request.fetchLimit = 1

        guard let log = try? context.fetch(request).first else { return }

        targetCalories = (log.value(forKey: "targetCalories") as? Double) ?? targetCalories
        actualCalories = (log.value(forKey: "actualCalories") as? Double) ?? 0
        actualProtein = (log.value(forKey: "proteinGrams") as? Double) ?? 0
        actualCarbs = (log.value(forKey: "carbsGrams") as? Double) ?? 0
        actualFat = (log.value(forKey: "fatGrams") as? Double) ?? 0
        actualWater = (log.value(forKey: "waterLiters") as? Double) ?? 0
    }

    // MARK: - Compute Targets

    func computeTargets() {
        guard weightKg > 0, heightCm > 0 else { return }

        // Determine age from profile (default 25 if not set)
        let age = computeAge()

        let body = BodyComposition(
            weightKg: weightKg,
            heightCm: heightCm,
            bodyFatPercent: bodyFatPercent,
            age: age,
            biologicalSex: loadBiologicalSex()
        )

        // Classify training day from today's workout data
        trainingDay = classifyTodayTraining()

        // Compute macro targets
        let targets = nutritionService.calculateMacros(
            body: body,
            goal: currentGoal,
            trainingDay: trainingDay
        )

        macroTargets = targets
        targetCalories = targets.calories
        targetProtein = targets.proteinGrams
        targetCarbs = targets.carbsGrams
        targetFat = targets.fatGrams
        targetWater = targets.waterLiters

        // Save targets to CoreData
        nutritionService.saveDailyLog(targets: targets, actual: nil, context: context)
    }

    // MARK: - Greek Ideal Analysis

    func loadGoldenRatio() {
        // Load latest morpho scan
        let request = NSFetchRequest<NSManagedObject>(entityName: "MorphoScan")
        request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        request.fetchLimit = 1

        guard let scan = try? context.fetch(request).first else { return }

        let shoulderWidth = (scan.value(forKey: "shoulderWidth") as? Double) ?? 0
        let hipWidth = (scan.value(forKey: "hipWidth") as? Double) ?? 0
        let torsoLength = (scan.value(forKey: "torsoLength") as? Double) ?? 0
        let femurLength = (scan.value(forKey: "femurLength") as? Double) ?? 0
        let tibiaLength = (scan.value(forKey: "tibiaLength") as? Double) ?? 0
        let humerusLength = (scan.value(forKey: "humerusLength") as? Double) ?? 0
        let forearmLength = (scan.value(forKey: "forearmLength") as? Double) ?? 0
        let armSpan = (scan.value(forKey: "armSpan") as? Double) ?? 0

        guard shoulderWidth > 0, hipWidth > 0 else { return }

        let measurements = SegmentMeasurements(
            torsoLength: torsoLength,
            femurLengthL: femurLength, femurLengthR: femurLength,
            tibiaLengthL: tibiaLength, tibiaLengthR: tibiaLength,
            humerusLengthL: humerusLength, humerusLengthR: humerusLength,
            forearmLengthL: forearmLength, forearmLengthR: forearmLength,
            shoulderWidth: shoulderWidth,
            hipWidth: hipWidth,
            armSpan: armSpan,
            heightCm: heightCm
        )

        let bf = bodyFatPercent > 0 ? bodyFatPercent : 15.0 // Default estimate
        let sex = loadBiologicalSex()

        goldenRatioResult = morphoScanner.goldenRatioScore(
            measurements: measurements,
            bodyFat: bf,
            biologicalSex: sex
        )

        // Generate nutrition plan based on Greek ideal gap
        if weightKg > 0 && heightCm > 0 {
            let body = BodyComposition(
                weightKg: weightKg,
                heightCm: heightCm,
                bodyFatPercent: bf,
                age: computeAge(),
                biologicalSex: sex
            )
            nutritionPlan = nutritionService.greekIdealPlan(
                body: body,
                currentBodyFat: bf,
                goldenRatioScore: goldenRatioResult?.overallScore ?? 0
            )
        }
    }

    // MARK: - Supplements

    func loadSupplements() {
        let sex = loadBiologicalSex()
        let idealBF = sex == "female" ? 18.0 : 10.0
        let bf = bodyFatPercent > 0 ? bodyFatPercent : 15.0

        // Sum weekly volume from muscle groups
        let muscleRequest = NSFetchRequest<NSManagedObject>(entityName: "MuscleGroup")
        let groups = (try? context.fetch(muscleRequest)) ?? []
        let weeklyVolume = groups.reduce(0) { $0 + Int((($1.value(forKey: "weeklyVolumeSets") as? Int16) ?? 0)) }

        // Get readiness from latest snapshot
        let snapRequest = NSFetchRequest<NSManagedObject>(entityName: "RecoverySnapshot")
        snapRequest.sortDescriptors = [NSSortDescriptor(key: "snapshotDate", ascending: false)]
        snapRequest.fetchLimit = 1
        let readiness = (try? context.fetch(snapRequest).first)
            .flatMap { $0.value(forKey: "overallReadiness") as? Double } ?? 80

        supplements = supplementAdvisor.recommend(
            bodyFatPercent: bf,
            idealBodyFat: idealBF,
            weeklyVolumeSets: weeklyVolume,
            readiness: readiness,
            goal: currentGoal,
            biologicalSex: sex
        )
    }

    // MARK: - Goal Change

    func setGoal(_ goal: NutritionGoal) {
        currentGoal = goal
        computeTargets()
        loadSupplements()
    }

    // MARK: - Full Refresh

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        // Try to get latest weight from HealthKit
        if let hkWeight = await nutritionService.fetchLatestWeight() {
            weightKg = hkWeight
            updateProfileWeight(hkWeight)
        }

        // Try to get latest body fat from HealthKit
        if let hkBF = await nutritionService.fetchLatestBodyFat() {
            bodyFatPercent = hkBF
            updateProfileBodyFat(hkBF)
        }

        computeTargets()
        loadGoldenRatio()
        loadSupplements()
    }

    // MARK: - Helpers

    private func computeAge() -> Int {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let profile = try? context.fetch(request).first,
              let dob = profile.value(forKey: "dateOfBirth") as? Date else { return 25 }

        let components = Calendar.current.dateComponents([.year], from: dob, to: Date())
        return components.year ?? 25
    }

    private func loadBiologicalSex() -> String {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let profile = try? context.fetch(request).first else { return "male" }
        return (profile.value(forKey: "biologicalSex") as? String) ?? "male"
    }

    private func classifyTodayTraining() -> TrainingDayType {
        let today = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<NSManagedObject>(entityName: "WorkoutSession")
        request.predicate = NSPredicate(format: "startTime >= %@", today as NSDate)

        guard let sessions = try? context.fetch(request), !sessions.isEmpty else {
            return .rest
        }

        // Get sets from today's sessions
        var totalSets = 0
        var totalRPE = 0.0
        var rpeCount = 0

        for session in sessions {
            if let sets = session.value(forKey: "workoutSets") as? NSOrderedSet {
                totalSets += sets.count
                for case let set as NSManagedObject in sets {
                    let rpe = (set.value(forKey: "rpe") as? Double) ?? 0
                    if rpe > 0 {
                        totalRPE += rpe
                        rpeCount += 1
                    }
                }
            }
        }

        let avgRPE = rpeCount > 0 ? totalRPE / Double(rpeCount) : 0
        return nutritionService.classifyTrainingDay(
            hasWorkoutToday: true,
            averageRPE: avgRPE,
            totalSets: totalSets
        )
    }

    private func updateProfileWeight(_ weight: Double) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let profile = try? context.fetch(request).first else { return }
        profile.setValue(weight, forKey: "weightKg")
        profile.setValue(Date(), forKey: "updatedAt")
        try? context.save()
    }

    private func updateProfileBodyFat(_ bf: Double) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserProfile")
        request.fetchLimit = 1
        guard let profile = try? context.fetch(request).first else { return }
        profile.setValue(bf, forKey: "bodyFatPercentage")
        profile.setValue(Date(), forKey: "updatedAt")
        try? context.save()
    }
}
