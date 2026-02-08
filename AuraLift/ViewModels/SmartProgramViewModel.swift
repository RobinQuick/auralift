import Foundation
import CoreData
import SwiftUI
import Combine

// MARK: - SmartProgramViewModel

/// Orchestrates the Pareto Aesthetic Engine: program generation, overload,
/// live adaptation, nutrition sync, and waist prediction.
@MainActor
final class SmartProgramViewModel: ObservableObject {

    // MARK: - Program State

    @Published var activeProgram: TrainingProgram?
    @Published var currentWeek: ProgramWeek?
    @Published var todayDay: ProgramDay?
    @Published var weekDays: [ProgramDay] = []
    @Published var todayExercises: [ProgramExercise] = []

    // MARK: - Setup Wizard State

    @Published var selectedFrequency: ProgramFrequency = .fullBody3
    @Published var selectedGoal: AestheticGoal = .greekMale
    @Published var selectedGymProfile: GymProfile?
    @Published var gymProfiles: [GymProfile] = []
    @Published var showSetupWizard: Bool = false

    // MARK: - Overload State

    @Published var overloadDecisions: [OverloadDecision] = []
    @Published var showOverloadSummary: Bool = false

    // MARK: - Live Adaptation State

    @Published var sessionAdaptation: SessionAdaptation?
    @Published var swapSuggestions: [ExerciseSwapSuggestion] = []
    @Published var showSwapSheet: Bool = false
    @Published var swappingExercise: ProgramExercise?

    // MARK: - Nutrition Sync State

    @Published var todayMacros: MacroTargets?
    @Published var trainingDayType: TrainingDayType = .rest
    @Published var nutritionDayLabel: String = "Rest — Low Carb, High Fat"

    // MARK: - Supplement Checklist State

    @Published var todaySupplements: [SupplementCheckItem] = []

    // MARK: - MetabolicFlux State

    @Published var metabolicAdjustment: MacroAdjustment?
    @Published var adaptiveTDEE: Double?

    // MARK: - Prediction State

    @Published var waistPrediction: String = ""
    @Published var readinessScore: Double = 100

    // MARK: - Premium Gating

    var canAccessSmartProgram: Bool { PremiumManager.shared.isPro }

    // MARK: - Services

    private let programBuilder = ParetoProgramBuilder()
    private let overloadManager = OverloadManager()
    private let liveAdapter = LiveSessionAdapter()
    private let nutritionService = NutritionService()

    // MARK: - CoreData

    private let context: NSManagedObjectContext

    // MARK: - Init

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Load Active Program

    func loadActiveProgram() {
        let request = NSFetchRequest<TrainingProgram>(entityName: "TrainingProgram")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        request.fetchLimit = 1

        activeProgram = try? context.fetch(request).first

        guard let program = activeProgram else {
            currentWeek = nil
            todayDay = nil
            weekDays = []
            todayExercises = []
            return
        }

        // Determine current week
        let weekNum = program.currentWeekNumber
        currentWeek = program.sortedWeeks.first { $0.weekNumber == Int16(weekNum) }

        // Load week days
        weekDays = currentWeek?.sortedDays ?? []

        // Find today's day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        todayDay = weekDays.first { day in
            guard let scheduled = day.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: today)
        }

        todayExercises = todayDay?.sortedExercises ?? []

        // Load gym profiles
        loadGymProfiles()

        // Determine training day type for nutrition (ON/OFF system)
        if todayDay?.isRestDay == true || todayDay == nil {
            trainingDayType = .rest
            nutritionDayLabel = "OFF — Low Carb, High Fat"
        } else {
            trainingDayType = todayExercises.count >= 5 ? .intense : .moderate
            nutritionDayLabel = "ON — High Carb"
        }

        // Load nutrition sync
        loadTodayMacros()

        // Load MetabolicFlux
        loadMetabolicFlux()

        // Load supplement checklist
        loadSupplementChecklist()

        // Calculate waist prediction
        calculateWaistPrediction()
    }

    // MARK: - Load Gym Profiles

    func loadGymProfiles() {
        let request = NSFetchRequest<GymProfile>(entityName: "GymProfile")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        gymProfiles = (try? context.fetch(request)) ?? []
        selectedGymProfile = gymProfiles.first { $0.isActive } ?? gymProfiles.first
    }

    // MARK: - Generate New Program

    func generateNewProgram() {
        guard let gymProfile = selectedGymProfile else { return }

        // Deactivate any existing active program
        if let existing = activeProgram {
            existing.isActive = false
        }

        // Load user profile
        let profileRequest = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        guard let userProfile = try? context.fetch(profileRequest).first else { return }

        // Load latest morpho data
        let (morphotype, measurements) = loadLatestMorphoData()

        // Generate the program
        let program = programBuilder.generateProgram(
            frequency: selectedFrequency,
            aestheticGoal: selectedGoal,
            gymProfile: gymProfile,
            userProfile: userProfile,
            morphotype: morphotype,
            measurements: measurements,
            context: context
        )

        // Estimate starting weights for first week
        estimateStartingWeights(
            program: program,
            bodyweight: userProfile.weightKg,
            sex: userProfile.biologicalSex ?? "male"
        )

        do {
            try context.save()
            activeProgram = program
            loadActiveProgram()
        } catch {
            context.rollback()
        }
    }

    // MARK: - Process Week End

    func processWeekEnd() {
        guard let current = currentWeek,
              let program = activeProgram else { return }

        current.isComplete = true

        // Find next week
        let nextWeekNum = current.weekNumber + 1
        guard let nextWeek = program.sortedWeeks.first(where: { $0.weekNumber == nextWeekNum }) else {
            return
        }

        // Calculate overload decisions
        overloadDecisions = overloadManager.processWeekEnd(
            completedWeek: current,
            nextWeek: nextWeek,
            context: context
        )
        showOverloadSummary = !overloadDecisions.isEmpty
    }

    // MARK: - Check Session Adaptation

    func checkSessionAdaptation() {
        let isDeload = currentWeek?.parsedWeekType == .deload

        // Load latest recovery snapshot
        let request = NSFetchRequest<RecoverySnapshot>(entityName: "RecoverySnapshot")
        request.sortDescriptors = [NSSortDescriptor(key: "snapshotDate", ascending: false)]
        request.fetchLimit = 1

        if let snapshot = try? context.fetch(request).first {
            readinessScore = snapshot.overallReadiness
            let cyclePhaseStr = snapshot.cyclePhase
            let cyclePhase = cyclePhaseStr.flatMap { CyclePhase(rawValue: $0) }

            sessionAdaptation = liveAdapter.checkAutoReg(
                readinessScore: readinessScore,
                cyclePhase: cyclePhase,
                deload: isDeload
            )
        }
    }

    // MARK: - Request Swap

    func requestSwap(for programExercise: ProgramExercise) {
        guard let exercise = programExercise.exercise,
              let gymProfile = selectedGymProfile else { return }

        let measurements = loadLatestMorphoData().1
        swappingExercise = programExercise

        swapSuggestions = liveAdapter.suggestSwaps(
            for: exercise,
            weight: programExercise.targetWeightKg,
            reps: programExercise.repRange.min,
            targetRPE: programExercise.targetRPE,
            gymProfile: gymProfile,
            measurements: measurements,
            context: context
        )
        showSwapSheet = !swapSuggestions.isEmpty
    }

    // MARK: - Apply Swap

    func applySwap(_ suggestion: ExerciseSwapSuggestion, for programExercise: ProgramExercise) {
        programExercise.exercise = suggestion.exercise
        programExercise.targetWeightKg = suggestion.suggestedWeight
        programExercise.targetReps = suggestion.suggestedReps
        programExercise.whyMessage = "Swapped: \(suggestion.whyMessage)"

        do {
            try context.save()
            todayExercises = todayDay?.sortedExercises ?? []
        } catch {
            context.rollback()
        }

        showSwapSheet = false
        swappingExercise = nil
    }

    // MARK: - Mark Day Completed

    func markDayCompleted(sessionId: UUID) {
        guard let day = todayDay else { return }
        day.isCompleted = true
        day.completedSessionId = sessionId

        // Mark all exercises as completed
        for ex in day.sortedExercises {
            ex.isCompleted = true
        }

        // Check if all training days for the week are complete
        if let week = currentWeek {
            let allTrainingComplete = week.trainingDays.allSatisfy(\.isCompleted)
            if allTrainingComplete {
                processWeekEnd()
            }
        }

        do {
            try context.save()
        } catch {
            context.rollback()
        }
    }

    // MARK: - MetabolicFlux

    private func loadMetabolicFlux() {
        // Load weight entries from NutritionLog for the last 14 days
        let calendar = Calendar.current
        guard let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date()) else { return }

        let logRequest = NSFetchRequest<NSManagedObject>(entityName: "NutritionLog")
        logRequest.predicate = NSPredicate(format: "logDate >= %@", twoWeeksAgo as NSDate)
        logRequest.sortDescriptors = [NSSortDescriptor(key: "logDate", ascending: true)]

        guard let logs = try? context.fetch(logRequest), logs.count >= 7 else {
            metabolicAdjustment = nil
            adaptiveTDEE = nil
            return
        }

        // Build WeightEntry array from logs
        let profileRequest = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        guard let profile = try? context.fetch(profileRequest).first else { return }

        let baseWeight = profile.weightKg
        let entries: [WeightEntry] = logs.compactMap { log in
            guard let date = log.value(forKey: "logDate") as? Date else { return nil }
            let calories = log.value(forKey: "actualCalories") as? Double ?? log.value(forKey: "targetCalories") as? Double ?? 0
            return WeightEntry(date: date, weightKg: baseWeight, calorieIntake: calories)
        }

        guard !entries.isEmpty else { return }

        let flux = MetabolicFlux()
        adaptiveTDEE = flux.smoothedTDEE(entries: entries)

        if let tdee = adaptiveTDEE {
            metabolicAdjustment = flux.weeklyRecalculate(
                currentTDEE: tdee,
                entries: entries,
                goal: .maintenance
            )
        }
    }

    // MARK: - Nutrition Sync

    private func loadTodayMacros() {
        let profileRequest = NSFetchRequest<UserProfile>(entityName: "UserProfile")
        profileRequest.fetchLimit = 1
        guard let profile = try? context.fetch(profileRequest).first else { return }

        todayMacros = nutritionService.calculateMacros(
            weightKg: profile.weightKg,
            heightCm: profile.heightCm,
            age: profile.age,
            biologicalSex: profile.biologicalSex ?? "male",
            bodyFatPercentage: profile.bodyFatPercentage,
            goal: .maintenance,
            trainingDayType: trainingDayType
        )
    }

    // MARK: - Waist Prediction

    func calculateWaistPrediction() {
        guard activeProgram != nil else {
            waistPrediction = ""
            return
        }

        // Load latest morpho scan waist estimate
        let scanRequest = NSFetchRequest<MorphoScan>(entityName: "MorphoScan")
        scanRequest.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        scanRequest.fetchLimit = 1

        guard let scan = try? context.fetch(scanRequest).first,
              scan.waistEstimate > 0 else {
            waistPrediction = "Complete a body scan to unlock predictions"
            return
        }

        // Simple prediction: deficit + training → ~0.3cm/week waist reduction
        let weeksRemaining = max(0, 12 - (activeProgram?.currentWeekNumber ?? 0))
        let estimatedReduction = Double(weeksRemaining) * 0.3
        waistPrediction = String(format: "Waist: -%.1f cm in %d weeks", estimatedReduction, weeksRemaining)
    }

    // MARK: - Estimate Starting Weights

    private func estimateStartingWeights(program: TrainingProgram, bodyweight: Double, sex: String) {
        guard let firstWeek = program.sortedWeeks.first else { return }

        for day in firstWeek.trainingDays {
            for progEx in day.sortedExercises {
                guard let exercise = progEx.exercise else { continue }
                let estimated = overloadManager.estimateStartingWeight(
                    exerciseName: exercise.name,
                    bodyweight: bodyweight,
                    sex: sex,
                    targetRPE: progEx.targetRPE,
                    context: context
                )
                progEx.targetWeightKg = estimated
            }
        }
    }

    // MARK: - Supplement Checklist

    func loadSupplementChecklist() {
        todaySupplements = [
            SupplementCheckItem(name: "Creatine", dosage: "5g", timing: "Any time"),
            SupplementCheckItem(name: "Whey Protein", dosage: "25-40g", timing: "Post-workout"),
            SupplementCheckItem(name: "Vitamin D3", dosage: "4000 IU", timing: "With meal")
        ]
    }

    func toggleSupplement(_ item: SupplementCheckItem) {
        guard let idx = todaySupplements.firstIndex(where: { $0.id == item.id }) else { return }
        todaySupplements[idx].isChecked.toggle()
    }

    // MARK: - Morpho Data Loader

    private func loadLatestMorphoData() -> (Morphotype?, SegmentMeasurements?) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "MorphoScan")
        request.sortDescriptors = [NSSortDescriptor(key: "scanDate", ascending: false)]
        request.fetchLimit = 1

        guard let scan = try? context.fetch(request).first,
              let rawData = scan.value(forKey: "rawPoseData") as? Data,
              let heightCm = scan.value(forKey: "estimatedHeightCm") as? Double,
              heightCm > 0 else {
            return (nil, nil)
        }

        guard let dict = try? JSONSerialization.jsonObject(with: rawData) as? [String: [String: Double]] else {
            return (nil, nil)
        }

        var keypoints: [JointName: CGPoint] = [:]
        for (jointRaw, coords) in dict {
            guard let joint = JointName(rawValue: jointRaw),
                  let x = coords["x"],
                  let y = coords["y"] else { continue }
            keypoints[joint] = CGPoint(x: x, y: y)
        }

        var poseKeypoints: [JointName: PoseKeypoint] = [:]
        for (joint, point) in keypoints {
            poseKeypoints[joint] = PoseKeypoint(joint: joint, position: point, confidence: 1.0)
        }
        let frame = PoseFrame(keypoints: poseKeypoints, timestamp: 0)

        let scanner = MorphoScannerService()
        let measurements = scanner.computeMeasurements(frames: [frame], heightCm: heightCm)
        let morphotype = measurements.map { scanner.classifyMorphotype($0) }

        return (morphotype, measurements)
    }

    // MARK: - Save Gym Profile

    func saveGymProfile(name: String, equipment: [String], brands: [String]) {
        let profile = GymProfile(context: context)
        profile.name = name
        profile.availableEquipment = equipment.joined(separator: ",")
        profile.availableBrands = brands.joined(separator: ",")
        profile.isActive = true

        // Deactivate other profiles
        for existing in gymProfiles {
            existing.isActive = false
        }

        do {
            try context.save()
            loadGymProfiles()
        } catch {
            context.rollback()
        }
    }
}

// MARK: - SupplementCheckItem

/// Daily supplement checklist item (Creatine, Whey, etc.).
struct SupplementCheckItem: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let timing: String
    var isChecked: Bool = false
}

// MARK: - UserProfile Age Helper

private extension UserProfile {
    var age: Int {
        guard let dob = dateOfBirth else { return 30 }
        return Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 30
    }
}

// MARK: - NutritionService Extension

private extension NutritionService {
    func calculateMacros(
        weightKg: Double,
        heightCm: Double,
        age: Int,
        biologicalSex: String,
        bodyFatPercentage: Double,
        goal: NutritionGoal,
        trainingDayType: TrainingDayType
    ) -> MacroTargets? {
        guard weightKg > 0, heightCm > 0 else { return nil }

        // Mifflin-St Jeor BMR
        let bmr: Double
        if biologicalSex.lowercased() == "female" {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        } else {
            bmr = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
        }

        let activityMultiplier: Double = {
            switch trainingDayType {
            case .rest: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .intense: return 1.725
            }
        }()

        let tdee = bmr * activityMultiplier
        let calories = tdee * (1 + goal.calorieModifier)

        let protein = weightKg * goal.proteinMultiplier
        let fat = max(weightKg * 0.8, calories * 0.25 / 9)
        let carbs = max(0, (calories - protein * 4 - fat * 9) / 4)
        let water = weightKg * 0.033

        return MacroTargets(
            calories: calories,
            proteinGrams: protein,
            carbsGrams: carbs,
            fatGrams: fat,
            waterLiters: water
        )
    }
}
