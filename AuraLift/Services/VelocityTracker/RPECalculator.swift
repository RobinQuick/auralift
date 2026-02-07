import Foundation

// MARK: - VelocityZone

/// Velocity-based training zones for exercise categorization.
enum VelocityZone: String {
    case maxStrength     // < 0.5 m/s — heavy loads (>85% 1RM)
    case strength        // 0.5 - 0.75 m/s — strength range (70-85% 1RM)
    case strengthSpeed   // 0.75 - 1.0 m/s — strength-speed (55-70% 1RM)
    case speedStrength   // 1.0 - 1.3 m/s — speed-strength (40-55% 1RM)
    case speed           // > 1.3 m/s — speed/power (<40% 1RM)

    var displayName: String {
        switch self {
        case .maxStrength:   return "MAX STRENGTH"
        case .strength:      return "STRENGTH"
        case .strengthSpeed: return "STRENGTH-SPEED"
        case .speedStrength: return "SPEED-STRENGTH"
        case .speed:         return "SPEED"
        }
    }

    var colorHex: String {
        switch self {
        case .maxStrength:   return "FF4444" // Red
        case .strength:      return "FF6B00" // Orange
        case .strengthSpeed: return "FFD700" // Gold
        case .speedStrength: return "00D4FF" // Blue
        case .speed:         return "00FF88" // Green
        }
    }

    /// Determines the velocity zone from a given mean concentric velocity.
    static func from(velocity: Double) -> VelocityZone {
        switch velocity {
        case ..<0.5:      return .maxStrength
        case 0.5..<0.75:  return .strength
        case 0.75..<1.0:  return .strengthSpeed
        case 1.0..<1.3:   return .speedStrength
        default:          return .speed
        }
    }
}

// MARK: - RPECalculator

/// Estimates Rate of Perceived Exertion (RPE) from velocity loss percentage.
/// Based on research by Gonzalez-Badillo et al. mapping velocity loss to
/// proximity to failure, with exercise-specific adjustments.
final class RPECalculator: ServiceProtocol {

    var isAvailable: Bool { true }

    func initialize() async throws {}

    // MARK: - RPE from Velocity Loss

    /// Estimates RPE from the percentage of velocity lost during a set.
    /// Uses the Gonzalez-Badillo velocity loss → proximity to failure relationship.
    ///
    /// - Parameters:
    ///   - velocityLoss: Fraction of velocity lost (0.0 = no loss, 1.0 = complete stop).
    ///   - exerciseName: Optional exercise name for exercise-specific adjustments.
    /// - Returns: Estimated RPE on a 6.0 to 10.0 scale.
    func estimateRPE(velocityLoss: Double, exerciseName: String? = nil) -> Double {
        // Clamp input
        let loss = max(0, min(1.0, velocityLoss))

        // Base RPE from velocity loss curve (Gonzalez-Badillo approximation)
        // 0% loss ≈ RPE 6 (easy set)
        // 10% loss ≈ RPE 7
        // 20% loss ≈ RPE 8
        // 30% loss ≈ RPE 9
        // 40%+ loss ≈ RPE 10 (failure)
        let baseRPE: Double
        switch loss {
        case ..<0.05:  baseRPE = 6.0
        case ..<0.10:  baseRPE = 6.5
        case ..<0.15:  baseRPE = 7.0
        case ..<0.20:  baseRPE = 7.5
        case ..<0.25:  baseRPE = 8.0
        case ..<0.30:  baseRPE = 8.5
        case ..<0.35:  baseRPE = 9.0
        case ..<0.40:  baseRPE = 9.5
        default:       baseRPE = 10.0
        }

        // Exercise-specific adjustment factor
        let adjustment = exerciseAdjustment(for: exerciseName)

        return min(10.0, max(1.0, baseRPE + adjustment))
    }

    // MARK: - Estimated 1RM

    /// Estimates 1RM from a given weight and mean concentric velocity.
    /// Uses the load-velocity relationship where velocity at 1RM ≈ exercise-specific minimum.
    ///
    /// - Parameters:
    ///   - weight: Weight lifted in kg.
    ///   - velocity: Mean concentric velocity in m/s.
    ///   - exerciseName: Exercise name for exercise-specific velocity at 1RM.
    /// - Returns: Estimated 1RM in kg, or nil if data is insufficient.
    func estimated1RM(weight: Double, velocity: Double, exerciseName: String? = nil) -> Double? {
        guard weight > 0, velocity > 0 else { return nil }

        let v1RM = velocityAt1RM(for: exerciseName)

        // Linear load-velocity model: %1RM = 1 - (velocity - v1RM) / slope
        // Simplified: 1RM ≈ weight / (1 - (velocity - v1RM) * slope)
        // Using empirical slope of ~0.6 for most exercises
        let slope = exerciseSlope(for: exerciseName)
        let estimated = weight / max(0.1, 1.0 - (velocity - v1RM) * slope)

        return max(weight, estimated) // 1RM can't be less than weight lifted
    }

    // MARK: - Reps in Reserve (RIR)

    /// Estimates reps in reserve from velocity loss.
    func estimateRIR(velocityLoss: Double) -> Int {
        switch velocityLoss {
        case ..<0.05:  return 5  // 5+ RIR
        case ..<0.10:  return 4
        case ..<0.15:  return 3
        case ..<0.20:  return 2
        case ..<0.30:  return 1
        case ..<0.40:  return 0  // At failure
        default:       return 0
        }
    }

    // MARK: - Exercise-Specific Parameters

    /// Velocity at 1RM for different exercises (m/s).
    /// Based on Gonzalez-Badillo & Sanchez-Medina (2010) research.
    private func velocityAt1RM(for exerciseName: String?) -> Double {
        guard let name = exerciseName else { return 0.17 }
        switch name {
        case "Barbell Back Squat":   return 0.30
        case "Barbell Bench Press":  return 0.17
        case "Overhead Press":       return 0.20
        case "Conventional Deadlift": return 0.15
        case "Romanian Deadlift":    return 0.20
        case "Barbell Row":          return 0.25
        case "Pull-Up":             return 0.20
        case "Lat Pulldown":        return 0.25
        case "Hip Thrust":          return 0.25
        default:                    return 0.17
        }
    }

    /// Load-velocity slope factor per exercise.
    private func exerciseSlope(for exerciseName: String?) -> Double {
        guard let name = exerciseName else { return 0.6 }
        switch name {
        case "Barbell Back Squat":   return 0.55
        case "Barbell Bench Press":  return 0.65
        case "Overhead Press":       return 0.60
        case "Conventional Deadlift": return 0.50
        default:                    return 0.60
        }
    }

    /// Exercise-specific RPE adjustment (some exercises tolerate more velocity loss).
    private func exerciseAdjustment(for exerciseName: String?) -> Double {
        guard let name = exerciseName else { return 0 }
        switch name {
        case "Barbell Back Squat":   return -0.5  // Squats tolerate more velocity loss
        case "Conventional Deadlift": return -0.5
        case "Pull-Up":             return 0.5   // Body weight = less tolerance
        default:                    return 0
        }
    }
}
