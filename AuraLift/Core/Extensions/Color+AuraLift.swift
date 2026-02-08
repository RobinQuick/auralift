import SwiftUI

extension Color {
    // MARK: - Primary Palette (AUREA — Clinical Luxury)

    /// Deep OLED void background
    static let aureaVoid = Color(hex: "000000")

    /// Gold — primary accent
    static let aureaPrimary = Color(hex: "D4AF37")

    /// Silver — secondary accent
    static let aureaSecondary = Color(hex: "C0C0C0")

    /// Muted green — success / optimal states
    static let aureaSuccess = Color(hex: "4CAF50")

    /// Muted rose — danger / alerts
    static let aureaAlert = Color(hex: "CF6679")

    /// Deep purple — special / elite tier
    static let aureaMystic = Color(hex: "7C4DFF")

    /// Prestige gold — achievements
    static let aureaPrestige = Color(hex: "FFD700")

    /// Clinical white — text on dark
    static let aureaWhite = Color(hex: "F5F5F5")

    /// Golden Ratio Gold
    static let aureaGold = Color(hex: "D4AF37")

    // MARK: - Legacy Aliases (keep for transitional compilation)

    static let auraBlack = aureaVoid
    static let neonBlue = aureaPrimary
    static let cyberOrange = aureaSecondary
    static let neonGreen = aureaSuccess
    static let neonRed = aureaAlert
    static let neonPurple = aureaMystic
    static let neonGold = aureaPrestige

    // MARK: - Surface Colors

    /// Dark surface for cards
    static let aureaSurface = Color(hex: "0A0A0F")

    /// Slightly lighter surface for elevated elements
    static let aureaSurfaceElevated = Color(hex: "12121A")

    /// Border color with subtle glow
    static let aureaBorder = Color(hex: "1A1A2E")

    // MARK: - Legacy Surface Aliases

    static let auraSurface = aureaSurface
    static let auraSurfaceElevated = aureaSurfaceElevated
    static let auraBorder = aureaBorder

    // MARK: - Text Colors

    /// Primary text — clinical white
    static let aureaTextPrimary = Color(hex: "F5F5F5")

    /// Secondary text — dimmed
    static let aureaTextSecondary = Color(hex: "8B8B9E")

    /// Disabled text
    static let aureaTextDisabled = Color(hex: "4A4A5A")

    // MARK: - Legacy Text Aliases

    static let auraTextPrimary = aureaTextPrimary
    static let auraTextSecondary = aureaTextSecondary
    static let auraTextDisabled = aureaTextDisabled

    // MARK: - Rank Tier Colors

    static let rankIron = Color(hex: "8B8B8B")
    static let rankBronze = Color(hex: "CD7F32")
    static let rankSilver = Color(hex: "C0C0C0")
    static let rankGold = Color(hex: "D4AF37")
    static let rankPlatinum = Color(hex: "E5E4E2")
    static let rankDiamond = Color(hex: "B9F2FF")
    static let rankMaster = Color(hex: "7C4DFF")
    static let rankGrandmaster = Color(hex: "CF6679")
    static let rankChallenger = Color(hex: "D4AF37")

    // MARK: - Hex Initializer

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
