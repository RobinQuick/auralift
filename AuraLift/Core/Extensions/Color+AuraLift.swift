import SwiftUI

extension Color {
    // MARK: - Primary Palette (Shadow Athlete)

    /// Deep OLED black background
    static let auraBlack = Color(hex: "000000")

    /// Neon Blue - primary accent
    static let neonBlue = Color(hex: "00D4FF")

    /// Cyber Orange - secondary accent / warnings
    static let cyberOrange = Color(hex: "FF6B00")

    /// Neon Green - success / optimal states
    static let neonGreen = Color(hex: "00FF88")

    /// Neon Red - danger / high risk
    static let neonRed = Color(hex: "FF4444")

    /// Neon Purple - special / mythic tier
    static let neonPurple = Color(hex: "9B59B6")

    /// Neon Gold - achievement / gold tier
    static let neonGold = Color(hex: "FFD700")

    // MARK: - Surface Colors

    /// Dark surface for cards
    static let auraSurface = Color(hex: "0A0A0F")

    /// Slightly lighter surface for elevated elements
    static let auraSurfaceElevated = Color(hex: "12121A")

    /// Border color with subtle glow
    static let auraBorder = Color(hex: "1A1A2E")

    // MARK: - Text Colors

    /// Primary text - bright white
    static let auraTextPrimary = Color(hex: "FFFFFF")

    /// Secondary text - dimmed
    static let auraTextSecondary = Color(hex: "8B8B9E")

    /// Disabled text
    static let auraTextDisabled = Color(hex: "4A4A5A")

    // MARK: - Rank Tier Colors

    static let rankIron = Color(hex: "8B8B8B")
    static let rankBronze = Color(hex: "CD7F32")
    static let rankSilver = Color(hex: "C0C0C0")
    static let rankGold = Color(hex: "FFD700")
    static let rankPlatinum = Color(hex: "00CED1")
    static let rankDiamond = Color(hex: "B9F2FF")
    static let rankMaster = Color(hex: "9B59B6")
    static let rankGrandmaster = Color(hex: "FF4444")
    static let rankChallenger = Color(hex: "FF6B00")

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
