import SwiftUI

// MARK: - AureaLeagueView

/// Prestige league dashboard showing tier progression, points breakdown, and Black Card preview.
struct AureaLeagueView: View {
    @StateObject private var league = AureaLeague()

    var body: some View {
        ScrollView {
            VStack(spacing: AureaTheme.Spacing.xl) {
                // MARK: - Header
                headerSection

                // MARK: - Tier Badge
                tierBadge

                // MARK: - Progress Ring
                progressSection

                // MARK: - Points Breakdown
                pointsBreakdown

                // MARK: - Next Tier Card
                nextTierCard

                // MARK: - Black Card Preview
                if league.currentTier == .elite {
                    blackCardPreview
                }

                Spacer(minLength: AureaTheme.Spacing.xxl)
            }
        }
        .aureaBackground()
        .navigationTitle("PRESTIGE LEAGUE")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AureaTheme.Spacing.sm) {
            Image(systemName: "building.columns.fill")
                .font(.system(size: 36))
                .aureaText(color: .aureaPrimary)

            Text("AUREA LEAGUE")
                .font(AureaTheme.Fonts.title())
                .aureaText(color: .aureaPrimary)

            Text("Season \(league.currentSeasonId)")
                .font(AureaTheme.Fonts.caption())
                .foregroundColor(.aureaTextSecondary)
        }
        .padding(.top, AureaTheme.Spacing.xl)
    }

    // MARK: - Tier Badge

    private var tierBadge: some View {
        VStack(spacing: AureaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.aureaSurfaceElevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.aureaPrimary.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .aureaPrimary.opacity(0.4), radius: 12)

                Image(systemName: league.currentTier.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(.aureaPrimary)
            }

            Text(league.currentTier.displayName.uppercased())
                .font(AureaTheme.Fonts.heading())
                .foregroundColor(.aureaPrimary)

            if league.isBlackCard {
                Text("BLACK CARD HOLDER")
                    .font(AureaTheme.Fonts.mono())
                    .foregroundColor(.aureaPrimary)
                    .padding(.horizontal, AureaTheme.Spacing.md)
                    .padding(.vertical, AureaTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(Color.aureaPrimary.opacity(0.15))
                    )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(league.currentTier.displayName) tier\(league.isBlackCard ? ", Black Card holder" : "")")
    }

    // MARK: - Progress Section

    private var progressSection: some View {
        let progress = league.progressToNextTier

        return VStack(spacing: AureaTheme.Spacing.md) {
            ZStack {
                Circle()
                    .stroke(Color.aureaSurfaceElevated, lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.aureaPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: .aureaPrimary.opacity(0.5), radius: 8)
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: AureaTheme.Spacing.xxs) {
                    Text("\(league.prestigePoints)")
                        .font(AureaTheme.Fonts.statValue(28))
                        .foregroundColor(.aureaTextPrimary)
                    Text("Prestige")
                        .font(AureaTheme.Fonts.caption())
                        .foregroundColor(.aureaTextSecondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(league.prestigePoints) prestige points, \(Int(progress * 100)) percent progress to next tier")

            if league.pointsToNextTier > 0 {
                Text("\(league.pointsToNextTier) points to \(league.currentTier.next?.displayName ?? "")")
                    .font(AureaTheme.Fonts.caption())
                    .foregroundColor(.aureaTextSecondary)
            }
        }
    }

    // MARK: - Points Breakdown

    private var pointsBreakdown: some View {
        VStack(spacing: AureaTheme.Spacing.md) {
            Text("HOW YOU EARN")
                .aureaSectionHeader()

            VStack(spacing: AureaTheme.Spacing.sm) {
                breakdownRow(label: "Session Quality", detail: "Up to 10 pts per session", icon: "star.fill")
                breakdownRow(label: "Consistency", detail: "+2 pts per training day", icon: "calendar.badge.checkmark")
                breakdownRow(label: "Form Bonus", detail: "+5 pts for 90%+ form", icon: "checkmark.seal.fill")
            }
            .padding(.horizontal, AureaTheme.Spacing.lg)
        }
    }

    private func breakdownRow(label: String, detail: String, icon: String) -> some View {
        HStack(spacing: AureaTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.aureaPrimary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(AureaTheme.Fonts.body())
                    .foregroundColor(.aureaTextPrimary)
                Text(detail)
                    .font(AureaTheme.Fonts.caption())
                    .foregroundColor(.aureaTextSecondary)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .aureaCard()
    }

    // MARK: - Next Tier Card

    private var nextTierCard: some View {
        Group {
            if let next = league.currentTier.next {
                VStack(spacing: AureaTheme.Spacing.md) {
                    Text("NEXT TIER")
                        .aureaSectionHeader()

                    HStack(spacing: AureaTheme.Spacing.md) {
                        Image(systemName: next.iconName)
                            .font(.system(size: 28))
                            .foregroundColor(.aureaSecondary)

                        VStack(alignment: .leading, spacing: AureaTheme.Spacing.xxs) {
                            Text(next.displayName.uppercased())
                                .font(AureaTheme.Fonts.subheading())
                                .foregroundColor(.aureaTextPrimary)
                            Text("\(next.pointsRequired) prestige points required")
                                .font(AureaTheme.Fonts.caption())
                                .foregroundColor(.aureaTextSecondary)
                        }

                        Spacer()

                        Text("\(league.pointsToNextTier)")
                            .font(AureaTheme.Fonts.mono())
                            .foregroundColor(.aureaPrimary)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Next tier: \(next.displayName), \(league.pointsToNextTier) points remaining out of \(next.pointsRequired) required")
                    .aureaCard()
                    .padding(.horizontal, AureaTheme.Spacing.lg)
                }
            }
        }
    }

    // MARK: - Black Card Preview

    private var blackCardPreview: some View {
        VStack(spacing: AureaTheme.Spacing.md) {
            Text("BLACK CARD")
                .aureaSectionHeader()

            VStack(spacing: AureaTheme.Spacing.md) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.aureaPrimary)

                Text("ARCHITECT")
                    .font(AureaTheme.Fonts.title())
                    .foregroundColor(.aureaPrimary)

                Text("The pinnacle of AUREA. Exclusive access to all future features, priority support, and permanent Black Card status.")
                    .font(AureaTheme.Fonts.body())
                    .foregroundColor(.aureaTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Black Card, Architect tier. The pinnacle of AUREA with exclusive access to all future features, priority support, and permanent Black Card status")
            .padding(AureaTheme.Spacing.xl)
            .background(Color.aureaVoid)
            .cornerRadius(AureaTheme.Radius.large)
            .overlay(
                RoundedRectangle(cornerRadius: AureaTheme.Radius.large)
                    .stroke(Color.aureaPrimary, lineWidth: 2)
            )
            .shadow(color: .aureaPrimary.opacity(0.3), radius: 16)
            .padding(.horizontal, AureaTheme.Spacing.lg)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AureaLeagueView()
    }
}
