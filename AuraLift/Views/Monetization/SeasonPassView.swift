import SwiftUI
import CoreData

// MARK: - SeasonPassView

/// Displays the 10-level season pass with dual-track (free + premium) rewards,
/// XP progress bar, and claim buttons.
struct SeasonPassView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SeasonViewModel
    @State private var showPaywall = false

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: SeasonViewModel(context: context))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                seasonHeader
                xpProgressSection
                rewardTrack
                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
            .padding(.top, AuraTheme.Spacing.lg)
        }
        .auraBackground()
        .navigationTitle("Season Pass")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { viewModel.loadSeasonData() }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Season Header

    private var seasonHeader: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Text("SAISON 0")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(viewModel.seasonName)
                .font(AuraTheme.Fonts.title(28))
                .cyberpunkText(color: .neonBlue)

            HStack(spacing: AuraTheme.Spacing.lg) {
                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.neonGold)
                    Text("Niveau \(viewModel.currentLevel)")
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(.auraTextPrimary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Level \(viewModel.currentLevel)")

                HStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: "clock")
                        .font(.system(size: 14))
                        .foregroundColor(.auraTextSecondary)
                    Text("\(viewModel.daysRemaining)j restants")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(viewModel.daysRemaining) days remaining")
            }
        }
    }

    // MARK: - XP Progress

    private var xpProgressSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            HStack {
                Text("\(viewModel.totalXP) XP")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonBlue)

                Spacer()

                Text("Niv. \(viewModel.currentLevel + 1): \(viewModel.progressCurrent)/\(viewModel.progressRequired)")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.auraSurfaceElevated)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.neonBlue, .cyberOrange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.progressPercent, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("XP progress: \(viewModel.totalXP) XP total, \(viewModel.progressCurrent) of \(viewModel.progressRequired) to next level")
    }

    // MARK: - Reward Track

    private var rewardTrack: some View {
        VStack(spacing: 0) {
            // Track header
            HStack {
                Text("NIVEAU")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
                    .frame(width: 50)

                Text("GRATUIT")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.neonGreen)
                    .frame(maxWidth: .infinity)

                Text("PREMIUM")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.neonGold)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.bottom, AuraTheme.Spacing.sm)

            // Level rows
            ForEach(viewModel.levels, id: \.level) { level in
                levelRow(level)
            }
        }
    }

    private func levelRow(_ level: SeasonLevel) -> some View {
        let isReached = viewModel.currentLevel >= level.level

        return HStack(spacing: AuraTheme.Spacing.sm) {
            // Level badge
            ZStack {
                Circle()
                    .fill(isReached ? Color.neonBlue : Color.auraSurfaceElevated)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle().stroke(
                            isReached ? Color.neonBlue.opacity(0.6) : Color.auraTextDisabled.opacity(0.3),
                            lineWidth: 1
                        )
                    )

                Text("\(level.level)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(isReached ? .auraBlack : .auraTextDisabled)
            }
            .frame(width: 50)
            .accessibilityLabel("Level \(level.level)\(isReached ? ", reached" : ", not reached")")

            // Free reward
            rewardCard(
                reward: level.freeReward,
                level: level,
                isPremiumTrack: false,
                accentColor: .neonGreen
            )

            // Premium reward
            rewardCard(
                reward: level.premiumReward,
                level: level,
                isPremiumTrack: true,
                accentColor: .neonGold
            )
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.xs)
    }

    private func rewardCard(
        reward: SeasonReward?,
        level: SeasonLevel,
        isPremiumTrack: Bool,
        accentColor: Color
    ) -> some View {
        Group {
            if let reward {
                let claimed = viewModel.isRewardClaimed(reward.id)
                let canClaim = viewModel.canClaimReward(reward, level: level, isPremiumTrack: isPremiumTrack)
                let locked = isPremiumTrack && !viewModel.isPro

                VStack(spacing: AuraTheme.Spacing.xs) {
                    Image(systemName: reward.iconName)
                        .font(.system(size: 18))
                        .foregroundColor(claimed ? accentColor : .auraTextSecondary)

                    Text(reward.displayName)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(claimed ? .auraTextPrimary : .auraTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    if claimed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.neonGreen)
                    } else if locked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.neonGold)
                    } else if canClaim {
                        Button {
                            viewModel.claimReward(reward)
                        } label: {
                            Text("CLAIM")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.auraBlack)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(accentColor))
                        }
                        .accessibilityLabel("Claim \(reward.displayName)")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, AuraTheme.Spacing.sm)
                .background(Color.auraSurfaceElevated)
                .cornerRadius(AuraTheme.Radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                        .stroke(claimed ? accentColor.opacity(0.4) : Color.clear, lineWidth: 0.5)
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("\(reward.displayName)\(claimed ? ", claimed" : locked ? ", locked, premium required" : canClaim ? ", available to claim" : ", not yet reached")")
                .onTapGesture {
                    if locked {
                        showPaywall = true
                    }
                }
            } else {
                // Empty slot
                Rectangle()
                    .fill(Color.auraSurface.opacity(0.3))
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .cornerRadius(AuraTheme.Radius.small)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SeasonPassView(context: PersistenceController.preview.container.viewContext)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
