import Foundation

/// All trackable muscle groups for recovery heatmap and exercise targeting.
enum MuscleGroupType: String, CaseIterable, Codable {
    // Upper Body - Push
    case chestUpper = "chest_upper"
    case chestLower = "chest_lower"
    case anteriorDeltoid = "anterior_deltoid"
    case lateralDeltoid = "lateral_deltoid"
    case posteriorDeltoid = "posterior_deltoid"
    case tricepsLong = "triceps_long"
    case tricepsLateral = "triceps_lateral"
    case tricepsMedial = "triceps_medial"

    // Upper Body - Pull
    case latsUpper = "lats_upper"
    case latsLower = "lats_lower"
    case trapsUpper = "traps_upper"
    case trapsMid = "traps_mid"
    case trapsLower = "traps_lower"
    case rhomboids = "rhomboids"
    case rearDelts = "rear_delts"
    case bicepsLong = "biceps_long"
    case bicepsShort = "biceps_short"
    case brachialis = "brachialis"
    case forearms = "forearms"

    // Lower Body
    case quadriceps = "quadriceps"
    case hamstrings = "hamstrings"
    case gluteMax = "glute_max"
    case gluteMed = "glute_med"
    case adductors = "adductors"
    case calves = "calves"
    case tibialis = "tibialis"

    // Core
    case rectusAbdominis = "rectus_abdominis"
    case obliques = "obliques"
    case transverseAbdominis = "transverse_abdominis"
    case erectorSpinae = "erector_spinae"

    var displayName: String {
        switch self {
        case .chestUpper:           return "Upper Chest"
        case .chestLower:           return "Lower Chest"
        case .anteriorDeltoid:      return "Front Delts"
        case .lateralDeltoid:       return "Side Delts"
        case .posteriorDeltoid:     return "Rear Delts"
        case .tricepsLong:          return "Triceps (Long Head)"
        case .tricepsLateral:       return "Triceps (Lateral)"
        case .tricepsMedial:        return "Triceps (Medial)"
        case .latsUpper:            return "Upper Lats"
        case .latsLower:            return "Lower Lats"
        case .trapsUpper:           return "Upper Traps"
        case .trapsMid:             return "Mid Traps"
        case .trapsLower:           return "Lower Traps"
        case .rhomboids:            return "Rhomboids"
        case .rearDelts:            return "Rear Delts"
        case .bicepsLong:           return "Biceps (Long Head)"
        case .bicepsShort:          return "Biceps (Short Head)"
        case .brachialis:           return "Brachialis"
        case .forearms:             return "Forearms"
        case .quadriceps:           return "Quadriceps"
        case .hamstrings:           return "Hamstrings"
        case .gluteMax:             return "Glute Max"
        case .gluteMed:             return "Glute Med"
        case .adductors:            return "Adductors"
        case .calves:               return "Calves"
        case .tibialis:             return "Tibialis"
        case .rectusAbdominis:      return "Abs"
        case .obliques:             return "Obliques"
        case .transverseAbdominis:  return "TVA"
        case .erectorSpinae:        return "Erector Spinae"
        }
    }

    var bodyRegion: String {
        switch self {
        case .chestUpper, .chestLower, .anteriorDeltoid, .lateralDeltoid,
             .posteriorDeltoid, .tricepsLong, .tricepsLateral, .tricepsMedial,
             .latsUpper, .latsLower, .trapsUpper, .trapsMid, .trapsLower,
             .rhomboids, .rearDelts, .bicepsLong, .bicepsShort, .brachialis, .forearms:
            return "upper"
        case .quadriceps, .hamstrings, .gluteMax, .gluteMed, .adductors, .calves, .tibialis:
            return "lower"
        case .rectusAbdominis, .obliques, .transverseAbdominis, .erectorSpinae:
            return "core"
        }
    }
}
