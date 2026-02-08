import Foundation
import SwiftUI

// MARK: - ProgramFrequency

/// Training split frequency options for the Pareto program.
enum ProgramFrequency: String, CaseIterable, Codable {
    case fullBody3 = "full_body_3"
    case upperLower4 = "upper_lower_4"

    var daysPerWeek: Int {
        switch self {
        case .fullBody3: return 3
        case .upperLower4: return 4
        }
    }

    var displayName: String {
        switch self {
        case .fullBody3: return "Full Body 3x"
        case .upperLower4: return "Upper / Lower 4x"
        }
    }

    var description: String {
        switch self {
        case .fullBody3:
            return "3 sessions per week. Each session hits all major muscle groups. Best for beginners or busy schedules."
        case .upperLower4:
            return "4 sessions per week. Alternates upper and lower body days for higher volume per muscle."
        }
    }

    /// Returns day labels for a full week (Mon-Sun), marking rest days.
    var weekDayLabels: [String] {
        switch self {
        case .fullBody3:
            return ["Full Body A", "Rest", "Full Body B", "Rest", "Full Body C", "Rest", "Rest"]
        case .upperLower4:
            return ["Upper A", "Lower A", "Rest", "Upper B", "Lower B", "Rest", "Rest"]
        }
    }

    /// Indices of training days (0 = Monday).
    var trainingDayIndices: [Int] {
        switch self {
        case .fullBody3: return [0, 2, 4]
        case .upperLower4: return [0, 1, 3, 4]
        }
    }
}

// MARK: - AestheticGoal

/// Target physique archetype determining priority muscle groups.
enum AestheticGoal: String, CaseIterable, Codable {
    case greekMale = "greek_male"
    case hourglassFemale = "hourglass_female"

    var displayName: String {
        switch self {
        case .greekMale: return "Greek Statue"
        case .hourglassFemale: return "Hourglass"
        }
    }

    var description: String {
        switch self {
        case .greekMale:
            return "V-taper silhouette: wide shoulders, thick upper chest, wide lats, narrow waist."
        case .hourglassFemale:
            return "Hourglass curves: round glutes, defined hamstrings, toned quads, slim waist."
        }
    }

    var iconName: String {
        switch self {
        case .greekMale: return "figure.strengthtraining.traditional"
        case .hourglassFemale: return "figure.dance"
        }
    }

    var accentColor: Color {
        switch self {
        case .greekMale: return .neonBlue
        case .hourglassFemale: return .neonPurple
        }
    }

    /// Priority muscles receiving ~80% of total weekly volume (Pareto 20/80).
    var priorityMuscles: [String] {
        switch self {
        case .greekMale:
            return ["Side Delts", "Upper Chest", "Lats", "Rear Delts", "Traps"]
        case .hourglassFemale:
            return ["Glutes", "Hamstrings", "Quads", "Side Delts", "Upper Back"]
        }
    }

    /// Maintenance muscles receiving ~20% of total weekly volume (Pareto 20/80).
    var maintenanceMuscles: [String] {
        switch self {
        case .greekMale:
            return ["Quads", "Hamstrings", "Glutes", "Biceps", "Triceps", "Chest"]
        case .hourglassFemale:
            return ["Chest", "Triceps", "Biceps", "Calves", "Core"]
        }
    }

    /// Exercises that should NEVER be programmed unless a morpho deficit is detected.
    /// Anti-bullshit rule: no useless exercises that waste time.
    var bannedExercises: [String] {
        switch self {
        case .greekMale:
            return ["shrug", "forearm curl", "wrist curl", "neck curl"]
        case .hourglassFemale:
            return ["shrug", "forearm curl", "wrist curl", "neck curl",
                    "russian twist", "cable woodchop", "oblique crunch"]
        }
    }
}

// MARK: - ProgramWeekType

/// Periodization phase within the 12-week mesocycle.
enum ProgramWeekType: String, CaseIterable, Codable {
    case ramp = "ramp"
    case normal = "normal"
    case overload = "overload"
    case deload = "deload"

    var displayName: String {
        switch self {
        case .ramp: return "Ramp-Up"
        case .normal: return "Normal"
        case .overload: return "Overload"
        case .deload: return "Deload"
        }
    }

    var volumeModifier: Double {
        switch self {
        case .ramp: return 0.70
        case .normal: return 1.0
        case .overload: return 1.10
        case .deload: return 0.60
        }
    }

    var intensityModifier: Double {
        switch self {
        case .ramp: return 0.85
        case .normal: return 1.0
        case .overload: return 1.05
        case .deload: return 0.70
        }
    }

    var badgeColor: Color {
        switch self {
        case .ramp: return .neonBlue
        case .normal: return .neonGreen
        case .overload: return .cyberOrange
        case .deload: return .neonPurple
        }
    }

    /// Determines the week type for a given week number (1-indexed).
    static func type(for weekNumber: Int) -> ProgramWeekType {
        switch weekNumber {
        case 1...2: return .ramp
        case 3...8: return .normal
        case 9...11: return .overload
        case 12: return .deload
        default: return .normal
        }
    }
}

// MARK: - SessionMode

/// Real-time session adaptation mode.
enum SessionMode: String, Codable {
    case normal = "normal"
    case technique = "technique"
    case volume = "volume"

    var displayName: String {
        switch self {
        case .normal: return "Normal"
        case .technique: return "Technique"
        case .volume: return "Volume Mode"
        }
    }

    var description: String {
        switch self {
        case .normal: return "Standard training intensity"
        case .technique: return "Lighter weights, slower tempo, focus on form"
        case .volume: return "Reduced load (-20%), +2 reps for recovery"
        }
    }

    var badgeColor: Color {
        switch self {
        case .normal: return .neonGreen
        case .technique: return .cyberOrange
        case .volume: return .neonPurple
        }
    }
}
