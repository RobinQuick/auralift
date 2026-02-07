import SwiftUI

/// Central theme configuration for the AuraLift cyberpunk aesthetic.
enum AuraTheme {
    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum Radius {
        static let small: CGFloat = 6
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let pill: CGFloat = 100
    }

    // MARK: - Fonts

    enum Fonts {
        static func title(_ size: CGFloat = 28) -> Font {
            .system(size: size, weight: .black, design: .default)
        }

        static func heading(_ size: CGFloat = 22) -> Font {
            .system(size: size, weight: .bold, design: .default)
        }

        static func subheading(_ size: CGFloat = 17) -> Font {
            .system(size: size, weight: .semibold, design: .default)
        }

        static func body(_ size: CGFloat = 15) -> Font {
            .system(size: size, weight: .regular, design: .default)
        }

        static func caption(_ size: CGFloat = 12) -> Font {
            .system(size: size, weight: .medium, design: .default)
        }

        static func mono(_ size: CGFloat = 14) -> Font {
            .system(size: size, weight: .medium, design: .monospaced)
        }

        static func statValue(_ size: CGFloat = 36) -> Font {
            .system(size: size, weight: .black, design: .monospaced)
        }
    }

    // MARK: - Shadows

    enum Shadows {
        static func neonGlow(color: Color = .neonBlue, radius: CGFloat = 8) -> some View {
            EmptyView()
                .shadow(color: color.opacity(0.6), radius: radius)
        }

        static let glowRadius: CGFloat = 10
        static let subtleGlowRadius: CGFloat = 4
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.5)
    }

    // MARK: - Gradients

    static var neonBlueGradient: LinearGradient {
        LinearGradient(
            colors: [.neonBlue, .neonBlue.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cyberOrangeGradient: LinearGradient {
        LinearGradient(
            colors: [.cyberOrange, .cyberOrange.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var darkSurfaceGradient: LinearGradient {
        LinearGradient(
            colors: [.auraSurface, .auraBlack],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
