import SwiftUI
import CoreData

/// Main home screen showing the AURA LIFT title, XP progress, and quick stat cards.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var streakManager = CyberStreakManager.shared
    @ObservedObject private var questManager = DailyQuestManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    // MARK: - Header
                    headerSection

                    // MARK: - XP Progress
                    XPProgressBar(currentXP: 4_200, requiredXP: 10_000, tier: "Gold")
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // MARK: - Cyber-Streak Flame
                    cyberStreakCard

                    // MARK: - Daily Ops Card
                    dailyOpsCard

                    // MARK: - Season Pass Card
                    seasonPassCard

                    // MARK: - Quick Stats
                    quickStatsSection

                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
                .padding(.top, AuraTheme.Spacing.xl)
            }
            .auraBackground()
        }
    }

    // MARK: - Season Pass Card

    private var seasonPassCard: some View {
        NavigationLink {
            SeasonPassView(context: viewContext)
                .environment(\.managedObjectContext, viewContext)
        } label: {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.neonGold)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    Text("SEASON PASS")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)

                    Text("Alpha Protocol — Saison 0")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
            .darkCard()
            .neonGlow(color: .neonGold, radius: AuraTheme.Shadows.subtleGlowRadius)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Cyber-Streak Card

    private var cyberStreakCard: some View {
        NavigationLink {
            CyberStreakView()
        } label: {
            HStack(spacing: AuraTheme.Spacing.md) {
                // Flame icon with tier color
                Image(systemName: streakManager.streakTier.flameIcon)
                    .font(.system(size: 32))
                    .foregroundColor(streakFlameColor)
                    .shadow(color: streakFlameColor.opacity(0.5), radius: 6)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Text("\(streakManager.currentStreak)")
                            .font(AuraTheme.Fonts.statValue(24))
                            .foregroundColor(streakFlameColor)

                        Text("JOURS")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)

                        if streakManager.xpMultiplier > 1.0 {
                            Text("x\(String(format: "%.1f", streakManager.xpMultiplier)) XP")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(.auraBlack)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.neonGold))
                        }
                    }

                    Text(streakManager.streakTier.label)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                if streakManager.isAtRisk {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cyberOrange)
                }

                Image(systemName: "chevron.right")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
            .darkCard()
            .neonGlow(color: streakFlameColor, radius: AuraTheme.Shadows.subtleGlowRadius)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private var streakFlameColor: Color {
        switch streakManager.streakTier {
        case .none: return .auraTextDisabled
        case .spark, .burning: return .neonBlue
        case .blazing, .infernal: return .neonPurple
        case .mythic: return .neonGold
        }
    }

    // MARK: - Daily Ops Card

    private var dailyOpsCard: some View {
        NavigationLink {
            DailyOpsView()
        } label: {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "target")
                    .font(.system(size: 28))
                    .foregroundColor(.cyberOrange)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Text("CYBER-OPS")
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.auraTextPrimary)

                        Text("\(questManager.completedQuestCount)/3")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(questManager.allCompleted ? .neonGreen : .cyberOrange)
                    }

                    Text("Missions quotidiennes — \(questManager.totalQuestXP) XP")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                // Mini progress dots
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(i < questManager.completedQuestCount ? Color.neonGreen : Color.auraSurfaceElevated)
                            .frame(width: 8, height: 8)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
            .darkCard()
            .neonGlow(color: .cyberOrange, radius: AuraTheme.Shadows.subtleGlowRadius)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 44))
                .cyberpunkText(color: .neonBlue)

            Text("AURA LIFT")
                .font(AuraTheme.Fonts.title(34))
                .cyberpunkText(color: .neonBlue)

            Text("Shadow Athlete Protocol")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AuraTheme.Spacing.md)
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("TODAY")
                .auraSectionHeader()

            HStack(spacing: AuraTheme.Spacing.md) {
                statCard(
                    icon: "dumbbell.fill",
                    title: "Workout",
                    value: "Push A",
                    accent: .neonBlue
                )

                statCard(
                    icon: "trophy.fill",
                    title: "Rank",
                    value: "Gold IV",
                    accent: .neonGold
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            HStack(spacing: AuraTheme.Spacing.md) {
                statCard(
                    icon: "heart.fill",
                    title: "Recovery",
                    value: "87%",
                    accent: .neonGreen
                )

                statCard(
                    icon: "flame.fill",
                    title: "Streak",
                    value: "\(streakManager.currentStreak)j",
                    accent: streakFlameColor
                )
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    // MARK: - Stat Card

    private func statCard(icon: String, title: String, value: String, accent: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(accent)

            Text(title)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(value)
                .font(AuraTheme.Fonts.subheading())
                .foregroundColor(.auraTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .neonGlow(color: accent, radius: AuraTheme.Shadows.subtleGlowRadius)
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
