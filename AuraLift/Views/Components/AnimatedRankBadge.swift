import SwiftUI

/// Animated rank tier badge with neon glow and pulsing effect.
struct AnimatedRankBadge: View {
    let tier: RankTier
    var size: CGFloat = 80

    @State private var isGlowing = false

    private var tierColor: Color {
        Color(hex: tier.neonColorHex)
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(tierColor.opacity(0.3), lineWidth: 2)
                .frame(width: size + 16, height: size + 16)
                .scaleEffect(isGlowing ? 1.1 : 1.0)
                .opacity(isGlowing ? 0.5 : 0.8)

            // Main badge
            Circle()
                .fill(
                    RadialGradient(
                        colors: [tierColor.opacity(0.3), Color.auraSurface],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(tierColor, lineWidth: 2)
                )
                .shadow(color: tierColor.opacity(0.5), radius: 10)

            // Tier icon
            VStack(spacing: 2) {
                Image(systemName: tierIcon)
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(tierColor)

                Text(tier.displayName.uppercased())
                    .font(.system(size: size * 0.12, weight: .black))
                    .foregroundColor(tierColor)
            }
        }
        .animation(
            .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
            value: isGlowing
        )
        .onAppear { isGlowing = true }
    }

    private var tierIcon: String {
        switch tier {
        case .iron:         return "shield.fill"
        case .bronze:       return "shield.lefthalf.filled"
        case .silver:       return "shield.checkered"
        case .gold:         return "star.fill"
        case .platinum:     return "star.circle.fill"
        case .diamond:      return "diamond.fill"
        case .master:       return "crown.fill"
        case .grandmaster:  return "bolt.shield.fill"
        case .challenger:   return "flame.fill"
        }
    }
}

#Preview {
    ScrollView(.horizontal) {
        HStack(spacing: 20) {
            ForEach(RankTier.allCases, id: \.self) { tier in
                AnimatedRankBadge(tier: tier, size: 70)
            }
        }
        .padding()
    }
    .background(Color.auraBlack)
}
