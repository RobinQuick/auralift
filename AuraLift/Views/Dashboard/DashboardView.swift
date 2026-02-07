import SwiftUI
import CoreData

/// Main home screen showing the AURA LIFT title, XP progress, and quick stat cards.
struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    // MARK: - Header
                    headerSection

                    // MARK: - XP Progress
                    XPProgressBar(currentXP: 4_200, requiredXP: 10_000, tier: "Gold")
                        .padding(.horizontal, AuraTheme.Spacing.lg)

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
                    value: "12 days",
                    accent: .cyberOrange
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
