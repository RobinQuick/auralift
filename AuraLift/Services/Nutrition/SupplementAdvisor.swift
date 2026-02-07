import Foundation

// MARK: - Supplement Recommendation

/// An evidence-based supplement recommendation.
struct SupplementRecommendation: Identifiable {
    let id = UUID()
    let name: String
    let dosage: String
    let timing: String
    let icon: String           // SF Symbol
    let reason: String         // Why this is recommended
    let evidenceLevel: EvidenceLevel
    let priority: SupplementPriority
    let category: SupplementCategory
}

/// Strength of scientific evidence.
enum EvidenceLevel: String {
    case strong = "Strong"       // Multiple meta-analyses
    case moderate = "Moderate"   // RCTs available
    case emerging = "Emerging"   // Limited but promising data

    var displayBadge: String {
        switch self {
        case .strong:   return "A"
        case .moderate: return "B"
        case .emerging: return "C"
        }
    }
}

/// Recommendation priority.
enum SupplementPriority: Int, Comparable {
    case essential = 0    // Everyone should consider
    case recommended = 1  // Based on specific needs
    case optional = 2     // Nice to have

    static func < (lhs: SupplementPriority, rhs: SupplementPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .essential:   return "Essential"
        case .recommended: return "Recommended"
        case .optional:    return "Optional"
        }
    }
}

/// Supplement category.
enum SupplementCategory: String {
    case performance = "Performance"
    case recovery = "Recovery"
    case health = "Health"
    case bodyComposition = "Body Composition"
}

// MARK: - SupplementAdvisor

/// Suggests evidence-based supplements based on training volume, body composition,
/// recovery status, and Greek ideal deviation.
final class SupplementAdvisor: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - Generate Recommendations

    /// Generates personalized supplement recommendations based on current state.
    func recommend(
        bodyFatPercent: Double,
        idealBodyFat: Double,
        weeklyVolumeSets: Int,
        readiness: Double,
        goal: NutritionGoal,
        biologicalSex: String?
    ) -> [SupplementRecommendation] {
        var recs: [SupplementRecommendation] = []

        // === ESSENTIAL (everyone training seriously) ===

        // 1. Creatine Monohydrate — strongest evidence in sports nutrition
        recs.append(SupplementRecommendation(
            name: "Creatine Monohydrate",
            dosage: "5g",
            timing: "Any time, daily",
            icon: "bolt.fill",
            reason: "Increases strength, power output, and lean mass. Most researched supplement in history.",
            evidenceLevel: .strong,
            priority: .essential,
            category: .performance
        ))

        // 2. Whey Protein — if protein targets are hard to hit through food
        recs.append(SupplementRecommendation(
            name: "Whey Protein Isolate",
            dosage: "25-40g",
            timing: "Post-workout or between meals",
            icon: "cup.and.saucer.fill",
            reason: "Complete protein source with rapid absorption. Helps reach 2g+/kg protein target.",
            evidenceLevel: .strong,
            priority: .essential,
            category: .performance
        ))

        // 3. Vitamin D3 — widespread deficiency, especially in northern latitudes
        recs.append(SupplementRecommendation(
            name: "Vitamin D3",
            dosage: "4000 IU",
            timing: "With a fat-containing meal",
            icon: "sun.max.fill",
            reason: "Supports testosterone, bone health, and immune function. Most people are deficient.",
            evidenceLevel: .strong,
            priority: .essential,
            category: .health
        ))

        // === RECOMMENDED (based on specific needs) ===

        // 4. Omega-3 — anti-inflammatory, heart health
        if weeklyVolumeSets > 15 || readiness < 70 {
            recs.append(SupplementRecommendation(
                name: "Omega-3 Fish Oil",
                dosage: "2g EPA+DHA",
                timing: "With meals",
                icon: "drop.circle.fill",
                reason: "Reduces exercise-induced inflammation. Especially important at high training volumes.",
                evidenceLevel: .strong,
                priority: .recommended,
                category: .recovery
            ))
        }

        // 5. Magnesium — poor sleep or high training load
        if readiness < 60 || weeklyVolumeSets > 20 {
            recs.append(SupplementRecommendation(
                name: "Magnesium Glycinate",
                dosage: "400mg",
                timing: "Before bed",
                icon: "moon.stars.fill",
                reason: "Improves sleep quality and muscle recovery. Depleted by intense training.",
                evidenceLevel: .moderate,
                priority: .recommended,
                category: .recovery
            ))
        }

        // 6. Caffeine — pre-workout performance (not if readiness is too low)
        if readiness >= 50 {
            recs.append(SupplementRecommendation(
                name: "Caffeine",
                dosage: "3-6mg/kg (200-400mg)",
                timing: "30-60 min pre-workout",
                icon: "leaf.fill",
                reason: "Enhances strength, power, and endurance. Skip on rest or poor recovery days.",
                evidenceLevel: .strong,
                priority: .recommended,
                category: .performance
            ))
        }

        // === BODY COMPOSITION (based on Greek ideal gap) ===

        let bfGap = bodyFatPercent - idealBodyFat

        // 7. Green Tea Extract / Thermogenic — if cutting toward Greek ideal
        if bfGap > 3 && goal == .cut {
            recs.append(SupplementRecommendation(
                name: "Green Tea Extract (EGCG)",
                dosage: "500mg EGCG",
                timing: "With breakfast",
                icon: "flame.fill",
                reason: "Mild thermogenic effect (+3-4% metabolic rate). Natural fat oxidation support for your cut phase.",
                evidenceLevel: .moderate,
                priority: .recommended,
                category: .bodyComposition
            ))
        }

        // 8. L-Carnitine — fat transport (synergistic with exercise)
        if bfGap > 5 && goal == .cut {
            recs.append(SupplementRecommendation(
                name: "L-Carnitine L-Tartrate",
                dosage: "2g",
                timing: "With high-carb meal",
                icon: "arrow.right.circle.fill",
                reason: "Enhances fat transport into mitochondria. Most effective when combined with insulin spike (carbs).",
                evidenceLevel: .moderate,
                priority: .optional,
                category: .bodyComposition
            ))
        }

        // 9. Ashwagandha — stress/cortisol management in deficit
        if (bfGap > 3 && goal == .cut) || readiness < 50 {
            recs.append(SupplementRecommendation(
                name: "Ashwagandha (KSM-66)",
                dosage: "600mg",
                timing: "With dinner",
                icon: "brain.head.profile",
                reason: "Reduces cortisol and improves recovery. Caloric deficits raise cortisol — this helps preserve muscle.",
                evidenceLevel: .moderate,
                priority: .optional,
                category: .recovery
            ))
        }

        // === FEMALE-SPECIFIC ===

        if biologicalSex?.lowercased() == "female" {
            // 10. Iron — higher needs for menstruating women
            recs.append(SupplementRecommendation(
                name: "Iron Bisglycinate",
                dosage: "18mg",
                timing: "On empty stomach or with vitamin C",
                icon: "drop.fill",
                reason: "Female athletes lose iron through menstruation and sweat. Test ferritin levels first.",
                evidenceLevel: .moderate,
                priority: .recommended,
                category: .health
            ))
        }

        return recs.sorted { $0.priority < $1.priority }
    }

    // MARK: - Stack Summary

    /// Returns a concise summary of the recommended stack.
    func stackSummary(recommendations: [SupplementRecommendation]) -> String {
        let essential = recommendations.filter { $0.priority == .essential }
        let recommended = recommendations.filter { $0.priority == .recommended }
        let optional = recommendations.filter { $0.priority == .optional }

        var parts: [String] = []
        if !essential.isEmpty {
            parts.append("Core: \(essential.map(\.name).joined(separator: ", "))")
        }
        if !recommended.isEmpty {
            parts.append("Targeted: \(recommended.map(\.name).joined(separator: ", "))")
        }
        if !optional.isEmpty {
            parts.append("Optional: \(optional.map(\.name).joined(separator: ", "))")
        }

        return parts.joined(separator: ". ")
    }
}
