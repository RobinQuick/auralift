import Foundation

// MARK: - WeightEntry

/// A single weight measurement for TDEE smoothing.
struct WeightEntry {
    let date: Date
    let weightKg: Double
    let calorieIntake: Double
}

// MARK: - MacroAdjustment

/// Result of a weekly metabolic recalculation.
struct MacroAdjustment {
    let newCalories: Double
    let reason: String
    let previousCalories: Double

    var delta: Double { newCalories - previousCalories }
    var deltaLabel: String {
        let sign = delta >= 0 ? "+" : ""
        return "\(sign)\(Int(delta)) kcal"
    }
}

// MARK: - MetabolicFlux

/// Adaptive TDEE engine that smooths real weight data over 14 days to detect
/// metabolic trends and auto-adjust calories weekly.
final class MetabolicFlux {

    // MARK: - Smoothed TDEE

    /// Computes a smoothed TDEE from 14-day weight + intake data using exponential moving average.
    /// Returns nil if fewer than 7 entries are available.
    func smoothedTDEE(entries: [WeightEntry]) -> Double? {
        guard entries.count >= 7 else { return nil }

        let sorted = entries.sorted { $0.date < $1.date }
        let recent = Array(sorted.suffix(14))

        // Weight trend: EMA with alpha = 2/(n+1)
        let alpha = 2.0 / (Double(recent.count) + 1.0)
        var emaWeight = recent[0].weightKg
        for i in 1..<recent.count {
            emaWeight = alpha * recent[i].weightKg + (1 - alpha) * emaWeight
        }

        // Average calorie intake
        let avgIntake = recent.map(\.calorieIntake).reduce(0, +) / Double(recent.count)

        // Weight change over the period (kg)
        let weightChange = emaWeight - recent[0].weightKg
        let days = max(1, Calendar.current.dateComponents([.day], from: recent[0].date, to: recent[recent.count - 1].date).day ?? 14)

        // 1 kg of body weight ~ 7700 kcal
        let dailySurplus = (weightChange * 7700) / Double(days)

        // TDEE = intake - surplus (positive surplus means eating above TDEE)
        return avgIntake - dailySurplus
    }

    // MARK: - Weekly Recalculate

    /// Performs weekly macro adjustment based on weight trend and goal.
    /// Call every Monday with the latest data.
    func weeklyRecalculate(
        currentTDEE: Double,
        entries: [WeightEntry],
        goal: NutritionGoal
    ) -> MacroAdjustment? {
        let sorted = entries.sorted { $0.date < $1.date }
        guard sorted.count >= 14 else { return nil }

        let recent14 = Array(sorted.suffix(14))
        let firstWeek = Array(recent14.prefix(7))
        let secondWeek = Array(recent14.suffix(7))

        let avgWeightWeek1 = firstWeek.map(\.weightKg).reduce(0, +) / Double(firstWeek.count)
        let avgWeightWeek2 = secondWeek.map(\.weightKg).reduce(0, +) / Double(secondWeek.count)

        let weeklyChange = avgWeightWeek2 - avgWeightWeek1
        let bodyweightPercent = abs(weeklyChange) / avgWeightWeek2 * 100

        switch goal {
        case .cut:
            // Stagnant 2 weeks on cut → -80 kcal
            if abs(weeklyChange) < 0.1 {
                return MacroAdjustment(
                    newCalories: currentTDEE - 80,
                    reason: "Weight stagnant for 2 weeks on cut. Reducing by 80 kcal to restart progress.",
                    previousCalories: currentTDEE
                )
            }
            // Losing too fast (>1% BW/week) → +150 kcal
            if weeklyChange < 0 && bodyweightPercent > 1.0 {
                return MacroAdjustment(
                    newCalories: currentTDEE + 150,
                    reason: "Losing \(String(format: "%.1f", bodyweightPercent))% BW/week (>1%). Adding 150 kcal to preserve muscle.",
                    previousCalories: currentTDEE
                )
            }

        case .lean_bulk, .bulk:
            // Gaining too fast → -100 kcal
            if weeklyChange > 0 && bodyweightPercent > 0.5 {
                return MacroAdjustment(
                    newCalories: currentTDEE - 100,
                    reason: "Gaining \(String(format: "%.1f", bodyweightPercent))% BW/week. Reducing by 100 kcal to minimize fat gain.",
                    previousCalories: currentTDEE
                )
            }
            // Not gaining enough on bulk → +100 kcal
            if weeklyChange < 0.05 && goal == .bulk {
                return MacroAdjustment(
                    newCalories: currentTDEE + 100,
                    reason: "Insufficient weight gain on bulk. Adding 100 kcal.",
                    previousCalories: currentTDEE
                )
            }

        case .maintenance:
            // Drifting up → -50 kcal
            if weeklyChange > 0.2 {
                return MacroAdjustment(
                    newCalories: currentTDEE - 50,
                    reason: "Weight drifting up on maintenance. Small reduction of 50 kcal.",
                    previousCalories: currentTDEE
                )
            }
            // Drifting down → +50 kcal
            if weeklyChange < -0.2 {
                return MacroAdjustment(
                    newCalories: currentTDEE + 50,
                    reason: "Weight drifting down on maintenance. Small increase of 50 kcal.",
                    previousCalories: currentTDEE
                )
            }
        }

        return nil
    }
}
