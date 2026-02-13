import SwiftUI
import CoreData

/// Main home screen showing the AUREA title, XP progress, and quick stat cards.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject private var streakManager = CyberStreakManager.shared
    @ObservedObject private var questManager = DailyQuestManager.shared
    @StateObject private var league = AureaLeague()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    // MARK: - Header
                    headerSection

                    // MARK: - XP Progress
                    XPProgressBar(currentXP: 4_200, requiredXP: 10_000, tier: "Gold")
                        .padding(.horizontal, AuraTheme.Spacing.lg)

                    // MARK: - Aurea League Prestige
                    aureaLeagueCard

                    // MARK: - Cyber-Streak Flame
                    cyberStreakCard

                    // MARK: - Daily Ops Card
                    dailyOpsCard

                    // MARK: - Season Pass Card
                    seasonPassCard

                    // MARK: - Smart Program Card
                    smartProgramCard

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
        .accessibilityLabel("Season Pass, Alpha Protocol, Saison 0")
        .accessibilityHint("Opens the season pass details")
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
        .accessibilityLabel("Cyber Streak, \(streakManager.currentStreak) days, \(streakManager.streakTier.label)\(streakManager.xpMultiplier > 1.0 ? ", x\(String(format: "%.1f", streakManager.xpMultiplier)) XP multiplier" : "")\(streakManager.isAtRisk ? ", at risk" : "")")
        .accessibilityHint("Opens the streak details")
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
                .accessibilityHidden(true)

                Image(systemName: "chevron.right")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextDisabled)
            }
            .darkCard()
            .neonGlow(color: .cyberOrange, radius: AuraTheme.Shadows.subtleGlowRadius)
        }
        .accessibilityLabel("Cyber Ops, \(questManager.completedQuestCount) of 3 daily missions completed, \(questManager.totalQuestXP) XP")
        .accessibilityHint("Opens the daily missions")
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Smart Program Card

    private var smartProgramCard: some View {
        Group {
            if let program = activeProgramInfo {
                // Active program: show today's session
                NavigationLink {
                    HolisticCoachView(context: viewContext)
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    HStack(spacing: AuraTheme.Spacing.md) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 28))
                            .foregroundColor(.neonBlue)

                        VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                            HStack(spacing: AuraTheme.Spacing.xs) {
                                Text("AUREA BLUEPRINT")
                                    .font(AuraTheme.Fonts.subheading())
                                    .foregroundColor(.auraTextPrimary)

                                Text("Wk \(program.weekNumber)/12")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.neonBlue)
                            }

                            Text(program.todayLabel)
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.auraTextSecondary)
                        }

                        Spacer()

                        if !PremiumManager.shared.isPro {
                            PremiumBadge(.small)
                        }

                        Image(systemName: "chevron.right")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextDisabled)
                    }
                    .darkCard()
                    .neonGlow(color: .neonBlue, radius: AuraTheme.Shadows.subtleGlowRadius)
                }
                .accessibilityLabel("Aurea Blueprint, Week \(program.weekNumber) of 12, \(program.todayLabel)")
                .accessibilityHint("Opens your training program")
            } else {
                // No program: show CTA
                NavigationLink {
                    ProgramSetupWizardView(viewModel: SmartProgramViewModel(context: viewContext))
                        .environment(\.managedObjectContext, viewContext)
                } label: {
                    HStack(spacing: AuraTheme.Spacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 28))
                            .foregroundColor(.neonGreen)

                        VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                            Text("CREATE AUREA BLUEPRINT")
                                .font(AuraTheme.Fonts.subheading())
                                .foregroundColor(.auraTextPrimary)

                            Text("Aurea Intelligence — 12-week personalized blueprint")
                                .font(AuraTheme.Fonts.caption())
                                .foregroundColor(.auraTextSecondary)
                        }

                        Spacer()

                        if !PremiumManager.shared.isPro {
                            PremiumBadge(.small)
                        }

                        Image(systemName: "chevron.right")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextDisabled)
                    }
                    .darkCard()
                    .neonGlow(color: .neonGreen, radius: AuraTheme.Shadows.subtleGlowRadius)
                }
                .accessibilityLabel("Create Aurea Blueprint, 12-week personalized program")
                .accessibilityHint("Opens the program setup wizard")
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Active Program Info

    private struct ActiveProgramInfo {
        let weekNumber: Int
        let todayLabel: String
    }

    private var activeProgramInfo: ActiveProgramInfo? {
        let request = NSFetchRequest<TrainingProgram>(entityName: "TrainingProgram")
        request.predicate = NSPredicate(format: "isActive == YES")
        request.fetchLimit = 1
        guard let program = try? viewContext.fetch(request).first else { return nil }

        let weekNum = program.currentWeekNumber
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let week = program.sortedWeeks.first(where: { $0.weekNumber == Int16(weekNum) }) else {
            return ActiveProgramInfo(weekNumber: weekNum, todayLabel: "Week \(weekNum)")
        }

        if let day = week.sortedDays.first(where: { day in
            guard let scheduled = day.scheduledDate else { return false }
            return calendar.isDate(scheduled, inSameDayAs: today)
        }) {
            let label = day.isRestDay ? "Rest Day" : "\(day.dayLabel) — \(day.exerciseCount) exercises"
            return ActiveProgramInfo(weekNumber: weekNum, todayLabel: label)
        }

        return ActiveProgramInfo(weekNumber: weekNum, todayLabel: "Check your schedule")
    }

    // MARK: - Aurea League Card

    private var aureaLeagueCard: some View {
        NavigationLink {
            AureaLeagueView()
        } label: {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: league.currentTier.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(.aureaPrimary)
                    .shadow(color: .aureaPrimary.opacity(0.5), radius: 6)

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Text(league.currentTier.displayName.uppercased())
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.aureaPrimary)

                        Text("\(league.prestigePoints) pts")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.aureaTextSecondary)
                    }

                    if league.pointsToNextTier > 0 {
                        Text("\(league.pointsToNextTier) to \(league.currentTier.next?.displayName ?? "")")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.aureaTextSecondary)
                    } else {
                        Text("Maximum prestige achieved")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.aureaPrestige)
                    }
                }

                Spacer()

                // Mini progress ring
                ZStack {
                    Circle()
                        .stroke(Color.aureaSurfaceElevated, lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Circle()
                        .trim(from: 0, to: league.progressToNextTier)
                        .stroke(Color.aureaPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(-90))
                }
                .accessibilityHidden(true)

                Image(systemName: "chevron.right")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.aureaTextDisabled)
            }
            .aureaCard()
            .aureaGlow(color: .aureaPrimary, radius: AuraTheme.Shadows.subtleGlowRadius)
        }
        .accessibilityLabel("Aurea League, \(league.currentTier.displayName), \(league.prestigePoints) points, \(Int(league.progressToNextTier * 100)) percent progress\(league.pointsToNextTier > 0 ? ", \(league.pointsToNextTier) points to \(league.currentTier.next?.displayName ?? "next tier")" : ", maximum prestige achieved")")
        .accessibilityHint("Opens the prestige league")
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "bolt.shield.fill")
                .font(.system(size: 44))
                .aureaText(color: .aureaPrimary)

            Text("AUREA")
                .font(AuraTheme.Fonts.title(34))
                .aureaText(color: .aureaPrimary)

            Text(Aurea.tagline)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.aureaTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, AuraTheme.Spacing.md)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("AUREA. \(Aurea.tagline)")
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
                    value: activeProgramInfo?.todayLabel.prefix(8).description ?? "Push A",
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
