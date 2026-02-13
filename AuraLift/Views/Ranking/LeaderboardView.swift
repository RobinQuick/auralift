import SwiftUI
import CoreData

/// Personal leaderboard displaying the user's best workout sessions ranked by LP.
struct LeaderboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: RankingViewModel

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: RankingViewModel(context: ctx))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "list.number")
                    .font(.system(size: 32))
                    .cyberpunkText(color: viewModel.currentTier.color)

                Text("LEADERBOARD")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: viewModel.currentTier.color)

                Text("Personal Best Sessions")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
            .padding(.top, AuraTheme.Spacing.xl)
            .padding(.bottom, AuraTheme.Spacing.lg)

            // MARK: - Entries
            if viewModel.leaderboardEntries.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: AuraTheme.Spacing.sm) {
                        ForEach(viewModel.leaderboardEntries) { entry in
                            leaderboardRow(entry)
                        }
                    }
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                    .padding(.vertical, AuraTheme.Spacing.md)
                }
            }
        }
        .auraBackground()
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.auraTextDisabled)

            Text("No sessions recorded yet")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)

            Text("Complete a workout to see your ranking history")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, AuraTheme.Spacing.xl)
    }

    // MARK: - Leaderboard Row

    private func leaderboardRow(_ entry: LeaderboardEntry) -> some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            // Rank number
            Text("#\(entry.rank)")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(entry.rank <= 3 ? entry.tier.color : .auraTextSecondary)
                .frame(width: 36, alignment: .leading)

            // Tier and date
            VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                Text(entry.tier.displayName)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(entry.isCurrentSession ? entry.tier.color : .auraTextPrimary)

                Text(entry.date, style: .date)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            Spacer()

            // LP
            Text("\(entry.lp) LP")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(entry.tier.color)
        }
        .accessibilityElement(children: .combine)
        .darkCard()
        .if(entry.isCurrentSession) { view in
            view.neonGlow(color: entry.tier.color, radius: AuraTheme.Shadows.glowRadius)
        }
    }
}

// MARK: - Preview

#Preview {
    LeaderboardView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
