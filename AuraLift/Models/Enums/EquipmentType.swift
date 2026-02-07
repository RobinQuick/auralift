import Foundation

/// Equipment categories for exercise classification.
enum EquipmentType: String, CaseIterable, Codable {
    case barbell = "barbell"
    case dumbbell = "dumbbell"
    case cable = "cable"
    case machine = "machine"
    case smithMachine = "smith_machine"
    case bodyweight = "bodyweight"
    case band = "band"
    case kettlebell = "kettlebell"

    var displayName: String {
        switch self {
        case .barbell:      return "Barbell"
        case .dumbbell:     return "Dumbbell"
        case .cable:        return "Cable"
        case .machine:      return "Machine"
        case .smithMachine: return "Smith Machine"
        case .bodyweight:   return "Bodyweight"
        case .band:         return "Band"
        case .kettlebell:   return "Kettlebell"
        }
    }

    var iconName: String {
        switch self {
        case .barbell:      return "figure.strengthtraining.traditional"
        case .dumbbell:     return "dumbbell.fill"
        case .cable:        return "cable.connector"
        case .machine:      return "gearshape.fill"
        case .smithMachine: return "square.grid.3x3.topleft.filled"
        case .bodyweight:   return "figure.stand"
        case .band:         return "circle.dotted"
        case .kettlebell:   return "figure.strengthtraining.functional"
        }
    }
}
