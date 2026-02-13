import SwiftUI
import CoreData

/// Guild management view driven by CoreData GuildMembership entity.
/// Shows real guild data, current user as sole member (local-first),
/// and create/leave guild actions.
struct GuildView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SocialViewModel

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: SocialViewModel(context: ctx))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                // MARK: - Header
                VStack(spacing: AuraTheme.Spacing.sm) {
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 36))
                        .cyberpunkText(color: .neonGold)

                    Text("GUILD")
                        .font(AuraTheme.Fonts.title())
                        .cyberpunkText(color: .neonGold)
                }
                .padding(.top, AuraTheme.Spacing.xl)

                if let summary = viewModel.guildSummary {
                    // MARK: - Guild Banner
                    guildBanner(summary)

                    // MARK: - War Record
                    warRecordSection(summary)

                    // MARK: - Member (current user)
                    membersSection(summary)

                    // MARK: - Actions
                    NeonOutlineButton(title: "LEAVE GUILD", icon: "arrow.right.square", color: .neonRed) {
                        viewModel.leaveGuild()
                    }
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                } else {
                    // MARK: - Empty State
                    emptyState
                }

                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
        }
        .auraBackground()
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showCreateGuild) {
            createGuildSheet
        }
    }

    // MARK: - Guild Banner

    private func guildBanner(_ summary: GuildSummary) -> some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.auraSurfaceElevated)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .stroke(Color.neonGold.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: .neonGold.opacity(0.3), radius: 10, x: 0, y: 0)

                Text(summary.tag)
                    .font(AuraTheme.Fonts.heading())
                    .foregroundColor(.neonGold)
            }

            Text(summary.name.uppercased())
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .neonGold)

            Text("\(summary.memberCount) Member\(summary.memberCount == 1 ? "" : "s")")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Guild \(summary.name), tag \(summary.tag), \(summary.memberCount) member\(summary.memberCount == 1 ? "" : "s")")
        .frame(maxWidth: .infinity)
        .darkCard()
        .neonGlow(color: .neonGold, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - War Record

    private func warRecordSection(_ summary: GuildSummary) -> some View {
        HStack(spacing: AuraTheme.Spacing.xl) {
            VStack(spacing: AuraTheme.Spacing.xs) {
                Text("\(summary.warRecord.wins)")
                    .font(AuraTheme.Fonts.statValue(28))
                    .foregroundColor(.neonGreen)
                Text("Wins")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            Rectangle()
                .fill(Color.auraBorder)
                .frame(width: 1, height: 40)

            VStack(spacing: AuraTheme.Spacing.xs) {
                Text("\(summary.warRecord.losses)")
                    .font(AuraTheme.Fonts.statValue(28))
                    .foregroundColor(.neonRed)
                Text("Losses")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("War record: \(summary.warRecord.wins) wins, \(summary.warRecord.losses) losses")
        .frame(maxWidth: .infinity)
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Members

    private func membersSection(_ summary: GuildSummary) -> some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("MEMBERS")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.neonGold)

                    VStack(alignment: .leading, spacing: AuraTheme.Spacing.xxs) {
                        Text("You")
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.neonGold)

                        Text("\(summary.averageLP) LP")
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }

                    Spacer()

                    Text(summary.role.displayName)
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(summary.role.color)
                        .padding(.horizontal, AuraTheme.Spacing.sm)
                        .padding(.vertical, AuraTheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(summary.role.color.opacity(0.15))
                        )
                }
                .accessibilityElement(children: .combine)
                .darkCard()
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            Spacer().frame(height: AuraTheme.Spacing.xxl)

            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.auraTextDisabled)

            Text("No guild yet")
                .font(AuraTheme.Fonts.heading())
                .foregroundColor(.auraTextSecondary)

            Text("Create a guild to start competing")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)

            NeonButton(title: "CREATE GUILD", icon: "plus.circle.fill", color: .neonGold) {
                viewModel.showCreateGuild = true
            }
        }
    }

    // MARK: - Create Guild Sheet

    private var createGuildSheet: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            Text("CREATE GUILD")
                .font(AuraTheme.Fonts.title())
                .cyberpunkText(color: .neonGold)
                .padding(.top, AuraTheme.Spacing.xxl)

            VStack(spacing: AuraTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                    Text("GUILD NAME")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)

                    TextField("Enter guild name", text: $viewModel.newGuildName)
                        .font(AuraTheme.Fonts.body())
                        .foregroundColor(.auraTextPrimary)
                        .padding(AuraTheme.Spacing.md)
                        .background(Color.auraSurfaceElevated)
                        .cornerRadius(AuraTheme.Radius.small)
                }

                VStack(alignment: .leading, spacing: AuraTheme.Spacing.xs) {
                    Text("GUILD TAG (2-4 chars)")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)

                    TextField("e.g. IW", text: $viewModel.newGuildTag)
                        .font(AuraTheme.Fonts.body())
                        .foregroundColor(.auraTextPrimary)
                        .textInputAutocapitalization(.characters)
                        .padding(AuraTheme.Spacing.md)
                        .background(Color.auraSurfaceElevated)
                        .cornerRadius(AuraTheme.Radius.small)
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            Spacer()

            NeonButton(title: "CREATE", icon: "checkmark.circle.fill", color: .neonGold) {
                viewModel.createGuild()
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.bottom, AuraTheme.Spacing.xxl)
        }
        .auraBackground()
    }
}

// MARK: - Preview

#Preview {
    GuildView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
