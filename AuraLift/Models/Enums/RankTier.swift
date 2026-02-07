import Foundation
import SwiftUI

/// Competitive ranking tiers inspired by e-sport ranking systems.
/// Progression: Iron → Bronze → Silver → Gold → Platinum → Diamond → Master → Grandmaster → Challenger
enum RankTier: String, CaseIterable, Codable {
    case iron = "iron"
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"
    case diamond = "diamond"
    case master = "master"
    case grandmaster = "grandmaster"
    case challenger = "challenger"

    var displayName: String {
        rawValue.capitalized
    }

    var lpThreshold: Int32 {
        switch self {
        case .iron:         return 0
        case .bronze:       return 100
        case .silver:       return 250
        case .gold:         return 500
        case .platinum:     return 800
        case .diamond:      return 1200
        case .master:       return 1800
        case .grandmaster:  return 2500
        case .challenger:   return 3500
        }
    }

    var nextTier: RankTier? {
        let all = RankTier.allCases
        guard let idx = all.firstIndex(of: self), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    var neonColorHex: String {
        switch self {
        case .iron:         return "#8B8B8B"
        case .bronze:       return "#CD7F32"
        case .silver:       return "#C0C0C0"
        case .gold:         return "#FFD700"
        case .platinum:     return "#00CED1"
        case .diamond:      return "#B9F2FF"
        case .master:       return "#9B59B6"
        case .grandmaster:  return "#FF4444"
        case .challenger:   return "#FF6B00"
        }
    }

    var color: Color {
        switch self {
        case .iron:         return .rankIron
        case .bronze:       return .rankBronze
        case .silver:       return .rankSilver
        case .gold:         return .rankGold
        case .platinum:     return .rankPlatinum
        case .diamond:      return .rankDiamond
        case .master:       return .rankMaster
        case .grandmaster:  return .rankGrandmaster
        case .challenger:   return .rankChallenger
        }
    }

    var iconName: String {
        switch self {
        case .iron:         return "circle.fill"
        case .bronze:       return "shield.fill"
        case .silver:       return "shield.lefthalf.filled"
        case .gold:         return "shield.checkered"
        case .platinum:     return "diamond.fill"
        case .diamond:      return "star.fill"
        case .master:       return "crown.fill"
        case .grandmaster:  return "bolt.shield.fill"
        case .challenger:   return "flame.fill"
        }
    }
}
