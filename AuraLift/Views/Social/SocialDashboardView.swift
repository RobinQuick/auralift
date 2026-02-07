import SwiftUI
import CoreData

/// Main social hub with segment picker for Guild, Leaderboard, and Share sections.
struct SocialDashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: SocialViewModel

    @State private var selectedSegment = 0

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: SocialViewModel(context: ctx))
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 36))
                    .cyberpunkText(color: .neonBlue)

                Text("SOCIAL")
                    .font(AuraTheme.Fonts.title())
                    .cyberpunkText(color: .neonBlue)
            }
            .padding(.top, AuraTheme.Spacing.lg)

            // MARK: - Segment Picker
            Picker("Section", selection: $selectedSegment) {
                Text("Guild").tag(0)
                Text("Leaderboard").tag(1)
                Text("Share").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.vertical, AuraTheme.Spacing.md)

            // MARK: - Content
            ScrollView {
                switch selectedSegment {
                case 0:
                    guildSection
                case 1:
                    leaderboardSection
                case 2:
                    shareSection
                default:
                    EmptyView()
                }
            }
        }
        .auraBackground()
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $viewModel.showCreateGuild) {
            createGuildSheet
        }
        .sheet(isPresented: $viewModel.showShareSheet) {
            if let image = viewModel.shareCardImage {
                ShareSheet(items: [image])
            }
        }
    }

    // MARK: - Guild Section

    private var guildSection: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            if let summary = viewModel.guildSummary {
                // Guild banner
                guildBanner(summary)

                // War record
                warRecordCard(summary)

                // Member info (current user)
                currentUserCard(summary)

                // Leave guild button
                NeonOutlineButton(title: "LEAVE GUILD", icon: "arrow.right.square", color: .neonRed) {
                    viewModel.leaveGuild()
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
            } else {
                // Empty state — no guild
                emptyGuildState
            }

            Spacer(minLength: AuraTheme.Spacing.xxl)
        }
        .padding(.top, AuraTheme.Spacing.md)
    }

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
                    .shadow(color: .neonGold.opacity(0.3), radius: 10)

                Text(summary.tag)
                    .font(AuraTheme.Fonts.heading())
                    .foregroundColor(.neonGold)
            }

            Text(summary.name.uppercased())
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .neonGold)

            Text("Joined \(summary.joinDate, style: .date)")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .neonGlow(color: .neonGold, radius: AuraTheme.Shadows.subtleGlowRadius)
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func warRecordCard(_ summary: GuildSummary) -> some View {
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
        .frame(maxWidth: .infinity)
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func currentUserCard(_ summary: GuildSummary) -> some View {
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
        .darkCard()
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private var emptyGuildState: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            Spacer().frame(height: AuraTheme.Spacing.xxl)

            Image(systemName: "person.3.fill")
                .font(.system(size: 48))
                .foregroundColor(.auraTextDisabled)

            Text("No guild yet")
                .font(AuraTheme.Fonts.heading())
                .foregroundColor(.auraTextSecondary)

            Text("Create or join a guild to compete\nwith your training partners")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
                .multilineTextAlignment(.center)

            NeonButton(title: "CREATE GUILD", icon: "plus.circle.fill", color: .neonGold) {
                viewModel.showCreateGuild = true
            }
        }
    }

    // MARK: - Leaderboard Section

    private var leaderboardSection: some View {
        LeaderboardView()
            .environment(\.managedObjectContext, viewContext)
    }

    // MARK: - Share Section

    private var shareSection: some View {
        VStack(spacing: AuraTheme.Spacing.lg) {
            if let image = viewModel.shareCardImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(AuraTheme.Radius.medium)
                    .padding(.horizontal, AuraTheme.Spacing.lg)
                    .shadow(color: .neonBlue.opacity(0.3), radius: 12)

                NeonButton(title: "SHARE", icon: "square.and.arrow.up", color: .neonBlue) {
                    viewModel.showShareSheet = true
                }
                .padding(.horizontal, AuraTheme.Spacing.lg)
            } else {
                VStack(spacing: AuraTheme.Spacing.md) {
                    Spacer().frame(height: AuraTheme.Spacing.xxl)

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 48))
                        .foregroundColor(.auraTextDisabled)

                    Text("Generate a share card")
                        .font(AuraTheme.Fonts.heading())
                        .foregroundColor(.auraTextSecondary)

                    Text("Preview your latest session as a\ncyberpunk-styled card to share")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextDisabled)
                        .multilineTextAlignment(.center)

                    NeonOutlineButton(title: "GENERATE CARD", icon: "sparkles") {
                        viewModel.generateQuickShareCard()
                    }
                }
            }

            Spacer(minLength: AuraTheme.Spacing.xxl)
        }
        .padding(.top, AuraTheme.Spacing.md)
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

// MARK: - ShareSheet (UIActivityViewController)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
