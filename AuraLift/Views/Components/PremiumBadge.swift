import SwiftUI

// MARK: - PremiumBadge

/// Reusable crown + "PRO" capsule badge shown next to premium features or usernames.
struct PremiumBadge: View {
    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 14
            case .large: return 18
            }
        }

        var fontSize: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 10
            case .large: return 13
            }
        }

        var hPadding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }

        var vPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 3
            case .large: return 4
            }
        }
    }

    let size: BadgeSize

    init(_ size: BadgeSize = .medium) {
        self.size = size
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "crown.fill")
                .font(.system(size: size.iconSize))

            Text("PRO")
                .font(.system(size: size.fontSize, weight: .black, design: .monospaced))
        }
        .foregroundColor(.auraBlack)
        .padding(.horizontal, size.hPadding)
        .padding(.vertical, size.vPadding)
        .background(
            Capsule().fill(Color.neonGold)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PremiumBadge(.small)
        PremiumBadge(.medium)
        PremiumBadge(.large)
    }
    .padding()
    .auraBackground()
}
