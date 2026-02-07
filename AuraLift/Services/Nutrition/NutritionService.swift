import Foundation
import CoreData
import HealthKit

// MARK: - Nutrition Goal

/// Training phase / nutrition goal.
enum NutritionGoal: String, CaseIterable, Codable {
    case cut = "Cut"
    case maintenance = "Maintenance"
    case lean_bulk = "Lean Bulk"
    case bulk = "Bulk"

    var calorieModifier: Double {
        switch self {
        case .cut:         return -0.20   // -20% deficit
        case .maintenance: return 0.0
        case .lean_bulk:   return 0.10    // +10% surplus
        case .bulk:        return 0.20    // +20% surplus
        }
    }

    var proteinMultiplier: Double {
        switch self {
        case .cut:         return 2.4  // g/kg lean mass — preserve muscle in deficit
        case .maintenance: return 2.0
        case .lean_bulk:   return 2.2
        case .bulk:        return 1.8  // Lower because surplus handles anabolism
        }
    }
}

// MARK: - Training Day Type

/// Determines carb allocation for the day.
enum TrainingDayType: String {
    case rest = "Rest"
    case light = "Light"       // Technique, mobility, deload
    case moderate = "Moderate"  // Normal session
    case intense = "Intense"    // Heavy compounds, high RPE

    var carbModifier: Double {
        switch self {
        case .rest:     return 0.70   // -30% carbs on rest days
        case .light:    return 0.85
        case .moderate: return 1.00
        case .intense:  return 1.20   // +20% carbs for intense sessions
        }
    }
}

// MARK: - Macro Targets

/// Computed macronutrient targets for a given day.
struct MacroTargets {
    let calories: Double
    let proteinGrams: Double
    let carbsGrams: Double
    let fatGrams: Double
    let waterLiters: Double

    /// Percentage breakdown.
    var proteinPercent: Double {
        guard calories > 0 else { return 0 }
        return (proteinGrams * 4) / calories * 100
    }
    var carbsPercent: Double {
        guard calories > 0 else { return 0 }
        return (carbsGrams * 4) / calories * 100
    }
    var fatPercent: Double {
        guard calories > 0 else { return 0 }
        return (fatGrams * 9) / calories * 100
    }
}

// MARK: - Body Composition Input

/// User body composition data for macro calculation.
struct BodyComposition {
    let weightKg: Double
    let heightCm: Double
    let bodyFatPercent: Double
    let age: Int
    let biologicalSex: String    // "male" or "female"

    var leanMassKg: Double {
        weightKg * (1.0 - bodyFatPercent / 100.0)
    }

    var bmi: Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }
}

// MARK: - NutritionService

/// Dynamically calculates macronutrient targets based on training load, body composition,
/// and current goals. Implements carb cycling and recovery-aware adjustments.
final class NutritionService: ServiceProtocol {

    var isAvailable: Bool { true }

    private let healthStore = HKHealthStore()

    func initialize() async throws {}

    // MARK: - TDEE Calculation

    /// Computes Total Daily Energy Expenditure using Mifflin-St Jeor equation.
    /// More accurate than Harris-Benedict for modern populations.
    func calculateTDEE(body: BodyComposition, activityLevel: Double = 1.55) -> Double {
        let bmr: Double
        if body.biologicalSex.lowercased() == "female" {
            // Mifflin-St Jeor female
            bmr = 10 * body.weightKg + 6.25 * body.heightCm - 5 * Double(body.age) - 161
        } else {
            // Mifflin-St Jeor male
            bmr = 10 * body.weightKg + 6.25 * body.heightCm - 5 * Double(body.age) + 5
        }

        // Katch-McArdle adjustment if we have BF% (more accurate for athletes)
        let katchBMR: Double
        if body.bodyFatPercent > 0 && body.leanMassKg > 0 {
            katchBMR = 370 + 21.6 * body.leanMassKg
        } else {
            katchBMR = bmr
        }

        // Average both methods for best estimate
        let avgBMR = body.bodyFatPercent > 0 ? (bmr + katchBMR) / 2.0 : bmr

        return avgBMR * activityLevel
    }

    // MARK: - Macro Calculation

    /// Calculates daily macronutrient targets based on body composition, goal, and training day.
    func calculateMacros(
        body: BodyComposition,
        goal: NutritionGoal,
        trainingDay: TrainingDayType,
        readiness: Double = 100
    ) -> MacroTargets {
        let tdee = calculateTDEE(body: body)

        // Apply goal modifier
        var targetCalories = tdee * (1.0 + goal.calorieModifier)

        // Recovery adjustment: poor readiness → slightly more calories for recovery
        if readiness < 50 && goal == .cut {
            // Don't cut aggressively when recovery is low
            targetCalories = tdee * 0.95 // Mild deficit only
        }

        // Protein: based on lean body mass
        let proteinPerKg = goal.proteinMultiplier
        let proteinGrams = body.leanMassKg > 0
            ? body.leanMassKg * proteinPerKg
            : body.weightKg * 1.8 // Fallback if no BF% data
        let proteinCalories = proteinGrams * 4

        // Fat: minimum 0.8g/kg for hormonal health, typically 25-30% of calories
        let minFatGrams = body.weightKg * 0.8
        let fatCalories = max(minFatGrams * 9, targetCalories * 0.25)
        let fatGrams = fatCalories / 9

        // Carbs: fill remaining calories, adjusted by training day (carb cycling)
        let remainingCalories = max(0, targetCalories - proteinCalories - fatCalories)
        let baseCarbGrams = remainingCalories / 4
        let carbGrams = baseCarbGrams * trainingDay.carbModifier

        // Recalculate actual total after carb cycling
        let actualCalories = proteinCalories + (carbGrams * 4) + fatCalories

        // Water: ~35ml per kg body weight + training bonus
        let baseWater = body.weightKg * 0.035
        let trainingBonus: Double = trainingDay == .rest ? 0 : 0.5
        let waterLiters = baseWater + trainingBonus

        return MacroTargets(
            calories: actualCalories,
            proteinGrams: proteinGrams,
            carbsGrams: carbGrams,
            fatGrams: fatGrams,
            waterLiters: waterLiters
        )
    }

    // MARK: - Greek Ideal Nutrition Plan

    /// Generates a targeted nutrition plan to reach the Greek ideal body composition.
    /// The 20/80 approach: one clear, actionable recommendation.
    func greekIdealPlan(
        body: BodyComposition,
        currentBodyFat: Double,
        goldenRatioScore: Double
    ) -> NutritionPlan {
        let isFemale = body.biologicalSex.lowercased() == "female"
        let idealBF = isFemale ? 18.0 : 10.0
        let bfGap = currentBodyFat - idealBF

        let goal: NutritionGoal
        let carbReduction: Int
        let weeksDuration: Int
        let summary: String

        if bfGap > 5 {
            // Significant fat to lose
            goal = .cut
            carbReduction = 20 // -20% carbs on rest days
            weeksDuration = Int(bfGap * 1.5) // ~1.5 weeks per % BF
            summary = "You are at \(Int(currentBodyFat))% body fat. To reach the Greek ideal of \(Int(idealBF))%, we'll reduce carbs by \(carbReduction)% on rest days for \(weeksDuration) weeks."
        } else if bfGap > 2 {
            // Close to ideal, gentle cut
            goal = .cut
            carbReduction = 15
            weeksDuration = Int(bfGap * 2) // Slower for precision
            summary = "You are at \(Int(currentBodyFat))% body fat, close to the \(Int(idealBF))% ideal. Gentle carb reduction of \(carbReduction)% on rest days for \(weeksDuration) weeks will get you there."
        } else if bfGap > -2 {
            // At or near ideal — maintain
            goal = .maintenance
            carbReduction = 0
            weeksDuration = 0
            summary = "Your body fat is at the Greek ideal range. Maintain current nutrition and focus on proportional muscle development."
        } else {
            // Too lean or needs muscle
            goal = .lean_bulk
            carbReduction = 0
            weeksDuration = 12 // Standard lean bulk cycle
            summary = "At \(Int(currentBodyFat))% body fat, you have room for a lean bulk. Add +10% calories to build the proportions needed for the Greek ideal."
        }

        return NutritionPlan(
            goal: goal,
            carbReductionPercent: carbReduction,
            weeksDuration: weeksDuration,
            summary: summary,
            goldenRatioScore: goldenRatioScore
        )
    }

    // MARK: - Training Day Classification

    /// Classifies today's training day based on workout data.
    func classifyTrainingDay(
        hasWorkoutToday: Bool,
        averageRPE: Double,
        totalSets: Int
    ) -> TrainingDayType {
        guard hasWorkoutToday else { return .rest }

        if averageRPE >= 8.0 || totalSets >= 20 {
            return .intense
        } else if averageRPE >= 6.0 || totalSets >= 10 {
            return .moderate
        } else {
            return .light
        }
    }

    // MARK: - HealthKit Integration

    /// Reads the latest weight from HealthKit.
    func fetchLatestWeight() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable(),
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }

        try? await healthStore.requestAuthorization(toShare: [], read: [weightType])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let weight = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weight)
            }
            healthStore.execute(query)
        }
    }

    /// Reads the latest body fat percentage from HealthKit.
    func fetchLatestBodyFat() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable(),
              let bfType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return nil }

        try? await healthStore.requestAuthorization(toShare: [], read: [bfType])

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: bfType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, _ in
                let bf = (samples?.first as? HKQuantitySample)?
                    .quantity.doubleValue(for: .percent()) // 0.0 to 1.0
                continuation.resume(returning: bf.map { $0 * 100 })
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Save / Load CoreData

    /// Saves or updates today's nutrition log.
    func saveDailyLog(
        targets: MacroTargets,
        actual: MacroTargets?,
        context: NSManagedObjectContext
    ) {
        let today = Calendar.current.startOfDay(for: Date())
        let request = NSFetchRequest<NSManagedObject>(entityName: "NutritionLog")
        request.predicate = NSPredicate(format: "logDate >= %@", today as NSDate)
        request.fetchLimit = 1

        let log: NSManagedObject
        if let existing = try? context.fetch(request).first {
            log = existing
        } else {
            log = NSEntityDescription.insertNewObject(forEntityName: "NutritionLog", into: context)
            log.setValue(UUID(), forKey: "id")
            log.setValue(today, forKey: "logDate")
        }

        log.setValue(targets.calories, forKey: "targetCalories")

        if let actual = actual {
            log.setValue(actual.calories, forKey: "actualCalories")
            log.setValue(actual.proteinGrams, forKey: "proteinGrams")
            log.setValue(actual.carbsGrams, forKey: "carbsGrams")
            log.setValue(actual.fatGrams, forKey: "fatGrams")
            log.setValue(actual.waterLiters, forKey: "waterLiters")
        }

        try? context.save()
    }
}

// MARK: - Nutrition Plan

/// A targeted nutrition plan to reach body composition goals.
struct NutritionPlan {
    let goal: NutritionGoal
    let carbReductionPercent: Int
    let weeksDuration: Int
    let summary: String        // 20/80 actionable message
    let goldenRatioScore: Double
}
