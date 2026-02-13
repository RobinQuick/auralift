import SwiftUI

// MARK: - DailyOpsView

/// Full-screen view showing the 3 daily Cyber-Ops quests with progress bars
/// and XP rewards.
struct DailyOpsView: View {
    @ObservedObject private var questManager = DailyQuestManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                headerSection
                questsList
                xpSummary
                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
            .padding(.top, AuraTheme.Spacing.lg)
        }
        .auraBackground()
        .navigationTitle("Cyber-Ops")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { questManager.loadOrGenerateQuests() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "target")
                .font(.system(size: 44))
                .cyberpunkText(color: .cyberOrange)

            Text("CYBER-OPS QUOTIDIENNES")
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .cyberOrange)

            Text("3 missions. Renouvellement à minuit.")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            // Completion indicator
            HStack(spacing: AuraTheme.Spacing.sm) {
                ForEach(0..<3, id: \.self) { i in
                    let completed = i < questManager.completedQuestCount
                    Circle()
                        .fill(completed ? Color.neonGreen : Color.auraSurfaceElevated)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle().stroke(Color.neonGreen.opacity(0.5), lineWidth: 0.5)
                        )
                }
            }
            .padding(.top, AuraTheme.Spacing.xs)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(questManager.completedQuestCount) of 3 missions completed")
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Quests List

    private var questsList: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ForEach(questManager.quests) { quest in
                questCard(quest)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func questCard(_ quest: DailyQuest) -> some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(quest.isCompleted ? Color.neonGreen.opacity(0.2) : Color.auraSurfaceElevated)
                        .frame(width: 44, height: 44)

                    Image(systemName: quest.isCompleted ? "checkmark.circle.fill" : quest.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(quest.isCompleted ? .neonGreen : .cyberOrange)
                }

                // Title + description
                VStack(alignment: .leading, spacing: 2) {
                    Text(quest.title)
                        .font(AuraTheme.Fonts.subheading())
                        .foregroundColor(quest.isCompleted ? .neonGreen : .auraTextPrimary)
                        .strikethrough(quest.isCompleted)

                    Text(quest.description)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                        .lineLimit(2)
                }

                Spacer()

                // XP reward
                VStack(spacing: 2) {
                    Text("+\(quest.xpReward)")
                        .font(AuraTheme.Fonts.mono())
                        .foregroundColor(quest.isCompleted ? .neonGreen : .neonGold)

                    Text("XP")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.auraTextSecondary)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.auraSurfaceElevated)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(quest.isCompleted ? Color.neonGreen : Color.cyberOrange)
                        .frame(width: geometry.size.width * quest.progressPercent, height: 6)
                }
            }
            .frame(height: 6)
            .accessibilityHidden(true)
        }
        .darkCard()
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(quest.isCompleted ? Color.neonGreen.opacity(0.4) : Color.clear, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(quest.title), \(quest.description), \(quest.isCompleted ? "completed" : "\(Int(quest.progressPercent * 100)) percent progress"), +\(quest.xpReward) XP")
    }

    // MARK: - XP Summary

    private var xpSummary: some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "bolt.circle.fill")
                .font(.system(size: 22))
                .foregroundColor(.neonGold)

            VStack(alignment: .leading, spacing: 2) {
                let earned = questManager.quests.filter(\.isCompleted).reduce(Int64(0)) { $0 + $1.xpReward }
                Text("\(earned) / \(questManager.totalQuestXP) XP")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.auraTextPrimary)

                Text("XP des missions du jour")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            Spacer()

            if questManager.allCompleted {
                Text("COMPLÉTÉ")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.auraBlack)
                    .padding(.horizontal, AuraTheme.Spacing.sm)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.neonGreen))
            }
        }
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily missions XP, \(questManager.quests.filter(\.isCompleted).reduce(Int64(0), { $0 + $1.xpReward })) of \(questManager.totalQuestXP) XP earned\(questManager.allCompleted ? ", all completed" : "")")
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DailyOpsView()
    }
}
