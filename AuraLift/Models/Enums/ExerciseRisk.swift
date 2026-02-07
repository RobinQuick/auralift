import Foundation

/// Risk classification for exercises based on morpho-anatomical analysis.
/// Determined by limb ratios and lever mechanics.
enum ExerciseRisk: String, CaseIterable, Codable {
    case optimal = "optimal"
    case caution = "caution"
    case highRisk = "highRisk"

    var displayName: String {
        switch self {
        case .optimal:  return "Optimal"
        case .caution:  return "Caution"
        case .highRisk: return "High Risk"
        }
    }

    var colorHex: String {
        switch self {
        case .optimal:  return "#00FF88"
        case .caution:  return "#FFD700"
        case .highRisk: return "#FF4444"
        }
    }

    var description: String {
        switch self {
        case .optimal:
            return "Your proportions are well-suited for this movement. Low injury risk with proper form."
        case .caution:
            return "Your limb ratios create moderate leverage disadvantages. Pay attention to form cues."
        case .highRisk:
            return "Your anatomy creates significant leverage challenges. Consider alternative exercises."
        }
    }
}
