import SwiftUI
import CoreData

/// Displays the user's current competitive rank tier, LP progress,
/// promotion series status, and rank factor breakdown — all from real CoreData.
struct RankingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: RankingViewModel

    init() {
        // Temporary placeholder — overridden in .onAppear workaround below
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: RankingViewModel(context: ctx))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xxl) {
                    // MARK: - Header
                    VStack(spacing: AuraTheme.Spacing.sm) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 40))
                            .cyberpunkText(color: viewModel.currentTier.color)

                        Text("RANKING")
                            .font(AuraTheme.Fonts.title())
                            .cyberpunkText(color: viewModel.currentTier.color)
                    }
                    .padding(.top, AuraTheme.Spacing.xl)

                    // MARK: - Rank Badge
                    rankBadge

                    // MARK: - Promotion Series
                    if viewModel.isInPromotionSeries {
                        promotionSeriesSection
                    }

                    // MARK: - LP Progress
                    lpProgressSection

                    // MARK: - Rank Breakdown
                    rankBreakdown

                    // MARK: - Rank History
                    if !viewModel.rankHistory.isEmpty {
                        rankHistorySection
                    }

                    // MARK: - Social Link
                    socialLink

                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
            }
            .auraBackground()
            .onAppear {
                viewModel.loadData()
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "social" {
                    SocialDashboardView()
                        .environment(\.managedObjectContext, viewContext)
                }
            }
        }
    }

    // MARK: - Social Link

    private var socialLink: some View {
        NavigationLink(value: "social") {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.neonBlue)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    Text("SOCIAL HUB")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    Text("Guild, Leaderboard & Share")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.neonBlue)
            }
            .darkCard()
        }
        .accessibilityLabel("Social Hub")
        .accessibilityHint("Opens guild, leaderboard, and share features")
        .buttonStyle(.plain)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Rank Badge

    private var rankBadge: some View {
        let tier = viewModel.currentTier

        return VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.auraSurfaceElevated)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(tier.color.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: tier.color.opacity(0.4), radius: 16, x: 0, y: 0)

                VStack(spacing: AuraTheme.Spacing.xxs) {
                    Image(systemName: tier.iconName)
                        .font(.system(size: 36))
                        .foregroundColor(tier.color)

                    Text("\(viewModel.currentLP) LP")
                        .font(AuraTheme.Fonts.mono(12))
                        .foregroundColor(tier.color)
                }
            }

            Text(tier.displayName.uppercased())
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: tier.color)

            Text("\(viewModel.totalWorkouts) workouts completed")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tier.displayName) rank, \(viewModel.currentLP) league points, \(viewModel.totalWorkouts) workouts completed")
    }

    // MARK: - Promotion Series

    private var promotionSeriesSection: some View {
        let tier = viewModel.currentTier

        return VStack(spacing: AuraTheme.Spacing.sm) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(.cyberOrange)

                Text("PROMOTION SERIES")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.cyberOrange)

                Spacer()

                if let nextTier = tier.nextTier {
                    Text("→ \(nextTier.displayName)")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(nextTier.color)
                }
            }

            HStack(spacing: AuraTheme.Spacing.md) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index < viewModel.promotionSeriesWins
                              ? Color.neonGreen : Color.auraSurfaceElevated)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(index < viewModel.promotionSeriesWins
                                        ? Color.neonGreen.opacity(0.6)
                                        : Color.auraBorder, lineWidth: 1.5)
                        )
                        .if(index < viewModel.promotionSeriesWins) { view in
                            view.shadow(color: .neonGreen.opacity(0.5), radius: 6, x: 0, y: 0)
                        }
                }

                Spacer()

                Text("\(viewModel.promotionSeriesWins)/3 wins")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.cyberOrange)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Promotion series, \(viewModel.promotionSeriesWins) of 3 wins\(tier.nextTier.map { ", advancing to \($0.displayName)" } ?? "")")
        .darkCard()
        .neonGlow(color: .cyberOrange, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - LP Progress

    private var lpProgressSection: some View {
        let tier = viewModel.currentTier

        return VStack(spacing: AuraTheme.Spacing.sm) {
            HStack {
                Text(tier.displayName)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(tier.color)

                Spacer()

                if let nextTier = tier.nextTier {
                    Text("\(nextTier.displayName): \(nextTier.lpThreshold) LP")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                } else {
                    Text("MAX RANK")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(tier.color)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                        .fill(Color.auraSurfaceElevated)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: AuraTheme.Radius.pill)
                        .fill(tier.color)
                        .frame(width: geometry.size.width * viewModel.lpProgress, height: 10)
                        .shadow(color: tier.color.opacity(0.7), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 10)
            .accessibilityLabel("League points progress, \(Int(viewModel.lpProgress * 100)) percent")

            if viewModel.lpToNextTier > 0 {
                Text("\(viewModel.lpInTier) / \(viewModel.lpToNextTier) LP")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(tier.color)
            } else {
                Text("\(viewModel.currentLP) LP total")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(tier.color)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Rank Breakdown

    private var rankBreakdown: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("RANK FACTORS")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                rankFactor(
                    label: "Strength : Weight",
                    value: String(format: "%.2fx", viewModel.bestStrengthRatio),
                    icon: "scalemass.fill"
                )
                rankFactor(
                    label: "Form Quality",
                    value: String(format: "%.0f%%", viewModel.bestFormQuality),
                    icon: "checkmark.seal.fill"
                )
                rankFactor(
                    label: "Velocity Score",
                    value: String(format: "%.2f m/s", viewModel.bestVelocityScore),
                    icon: "gauge.with.dots.needle.33percent"
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func rankFactor(label: String, value: String, icon: String) -> some View {
        let tierColor = viewModel.currentTier.color

        return HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(tierColor)
                .frame(width: 28)

            Text(label)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)

            Spacer()

            Text(value)
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(tierColor)
        }
        .accessibilityElement(children: .combine)
        .darkCard()
    }

    // MARK: - Rank History

    private var rankHistorySection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("RECENT SESSIONS")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                ForEach(viewModel.rankHistory.prefix(5), id: \.date) { snapshot in
                    historyRow(snapshot)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func historyRow(_ snapshot: RankSnapshot) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                Text(snapshot.tier.displayName)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(snapshot.tier.color)

                Text(snapshot.date, style: .date)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AuraTheme.Spacing.xxs) {
                Text("\(snapshot.lp) LP")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(snapshot.tier.color)

                Text(String(format: "%.2fx", snapshot.strengthToWeightRatio))
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .darkCard()
    }
}

// MARK: - Preview

#Preview {
    RankingView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
