import SwiftUI
import CoreData

/// User profile and settings screen with avatar, rank badge, and app configuration options.
struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Mock profile data
    private let username = "ShadowAthlete"
    private let tier = "Gold"
    private let division = "IV"
    private let totalXP: Int64 = 42_350
    private let memberSince = "Jan 2025"

    @State private var showAudioSettings = false
    @State private var showPrivacyInfo = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteComplete = false

    // Beta unlock
    @State private var betaTapCount = 0
    @State private var showBetaUnlock = false
    @State private var betaCodeInput = ""
    @State private var betaUnlockSuccess = false

    private let settingsItems: [(icon: String, label: String, color: Color)] = [
        ("person.fill", "Edit Profile", .aureaMystic),
        ("ruler.fill", "Units & Measurements", .aureaPrimary),
        ("speaker.wave.3.fill", "Persona & Voice", .aureaPrimary),
        ("bell.fill", "Notifications", .aureaSecondary),
        ("heart.fill", "Health Integrations", .aureaSuccess),
        ("camera.fill", "Camera Settings", .aureaPrimary),
        ("lock.shield.fill", "Privacy", .aureaTextSecondary),
        ("questionmark.circle.fill", "Help & Support", .aureaTextSecondary),
        ("info.circle.fill", "About AUREA", .aureaTextSecondary),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                // MARK: - Header
                VStack(spacing: AuraTheme.Spacing.sm) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 36))
                        .cyberpunkText(color: .neonPurple)

                    Text("PROFILE")
                        .font(AuraTheme.Fonts.title())
                        .cyberpunkText(color: .neonPurple)
                }
                .padding(.top, AuraTheme.Spacing.xl)

                // MARK: - Avatar & Identity
                avatarSection

                // MARK: - Stats Row
                statsRow

                // MARK: - Settings
                settingsSection

                // MARK: - Delete Account
                deleteAccountButton

                Spacer(minLength: AuraTheme.Spacing.xxl)
            }
        }
        .auraBackground()
        .confirmationDialog(
            "Supprimer votre compte ?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Supprimer tout", role: .destructive) {
                performDeleteAccount()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text("Toutes vos données seront définitivement supprimées : entraînements, scans, classement et préférences. Cette action est irréversible.")
        }
        .overlay {
            if deleteComplete {
                deleteSuccessBanner
            }
        }
        .sheet(isPresented: $showAudioSettings) {
            AudioSettingsView()
        }
        .sheet(isPresented: $showPrivacyInfo) {
            PrivacyConsentView(
                onAccepted: { showPrivacyInfo = false },
                onRefused: { showPrivacyInfo = false }
            )
        }
        .sheet(isPresented: $showBetaUnlock) {
            betaUnlockSheet
        }
        .overlay {
            if betaUnlockSuccess {
                betaSuccessBanner
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.auraSurfaceElevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.neonPurple.opacity(0.6), lineWidth: 2)
                    )
                    .shadow(color: .neonPurple.opacity(0.4), radius: 12, x: 0, y: 0)

                Image(systemName: "person.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.neonPurple.opacity(0.7))
            }

            HStack(spacing: AuraTheme.Spacing.sm) {
                Text(username)
                    .font(AuraTheme.Fonts.heading())
                    .foregroundColor(.auraTextPrimary)

                if PremiumManager.shared.isPro {
                    PremiumBadge(.medium)
                }
            }

            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 14))
                    .foregroundColor(.neonGold)

                Text("\(tier) \(division)")
                    .font(AuraTheme.Fonts.mono())
                    .foregroundColor(.neonGold)
            }
            .padding(.horizontal, AuraTheme.Spacing.md)
            .padding(.vertical, AuraTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(Color.neonGold.opacity(0.15))
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Rank: \(tier) \(division)")

            Text("Member since \(memberSince)")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            profileStat(label: "Total XP", value: formatXP(totalXP), accent: .neonBlue)
            profileStat(label: "Workouts", value: "147", accent: .cyberOrange)
            profileStat(label: "Streak", value: "12d", accent: .neonGreen)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func profileStat(label: String, value: String, accent: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            Text(value)
                .font(AuraTheme.Fonts.statValue(20))
                .foregroundColor(accent)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Text("SETTINGS")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.sm) {
                ForEach(settingsItems, id: \.label) { item in
                    if item.label == "Persona & Voice" {
                        Button { showAudioSettings = true } label: {
                            settingsRow(item)
                        }
                        .accessibilityLabel("Persona & Voice")
                        .accessibilityHint("Opens persona and voice settings")
                    } else if item.label == "Privacy" {
                        Button { showPrivacyInfo = true } label: {
                            settingsRow(item)
                        }
                        .accessibilityLabel("Privacy")
                        .accessibilityHint("Opens privacy information")
                    } else if item.label == "About AUREA" {
                        Button {
                            betaTapCount += 1
                            if betaTapCount >= 5 {
                                betaTapCount = 0
                                showBetaUnlock = true
                            }
                        } label: {
                            HStack(spacing: AuraTheme.Spacing.md) {
                                Image(systemName: item.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(item.color)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.label)
                                        .font(AuraTheme.Fonts.body())
                                        .foregroundColor(.auraTextPrimary)
                                    Text("Version 0.1.0")
                                        .font(AuraTheme.Fonts.caption())
                                        .foregroundColor(.auraTextDisabled)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(AuraTheme.Fonts.caption())
                                    .foregroundColor(.auraTextDisabled)
                            }
                            .darkCard()
                        }
                        .accessibilityLabel("About AUREA, Version 0.1.0")
                        .accessibilityHint("Opens app information")
                    } else {
                        settingsRow(item)
                            .accessibilityElement(children: .combine)
                    }
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func settingsRow(_ item: (icon: String, label: String, color: Color)) -> some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: item.icon)
                .font(.system(size: 18))
                .foregroundColor(item.color)
                .frame(width: 28)

            Text(item.label)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextDisabled)
        }
        .darkCard()
    }

    // MARK: - Delete Account

    private var deleteAccountButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: AuraTheme.Spacing.sm) {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .neonRed))
                } else {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16))
                }

                Text("SUPPRIMER MON COMPTE ET MES DONNÉES")
                    .font(AuraTheme.Fonts.subheading())
            }
            .foregroundColor(.neonRed)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(Color.neonRed.opacity(0.3), lineWidth: 0.5)
            )
        }
        .disabled(isDeleting)
        .accessibilityLabel("Delete my account and data")
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.top, AuraTheme.Spacing.md)
    }

    // MARK: - Delete Success Banner

    private var deleteSuccessBanner: some View {
        VStack {
            Spacer()

            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.neonGreen)
                Text("Compte et données supprimés")
                    .font(AuraTheme.Fonts.body())
                    .foregroundColor(.auraTextPrimary)
            }
            .padding(AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.medium)
            .neonGlow(color: .neonGreen, radius: 8, cornerRadius: AuraTheme.Radius.medium)
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.bottom, AuraTheme.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { deleteComplete = false }
            }
        }
    }

    // MARK: - Beta Unlock Sheet

    private var betaUnlockSheet: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .cyberpunkText(color: .neonGold)

            Text("BETA ACCESS CODE")
                .font(AuraTheme.Fonts.heading())
                .cyberpunkText(color: .neonGold)

            Text("Entre ton code d'accès alpha pour débloquer AUREA Pro pendant 3 mois.")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AuraTheme.Spacing.xl)

            TextField("Code d'accès", text: $betaCodeInput)
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.auraTextPrimary)
                .multilineTextAlignment(.center)
                .padding(AuraTheme.Spacing.md)
                .background(Color.auraSurfaceElevated)
                .cornerRadius(AuraTheme.Radius.small)
                .overlay(
                    RoundedRectangle(cornerRadius: AuraTheme.Radius.small)
                        .stroke(Color.neonGold.opacity(0.3), lineWidth: 0.5)
                )
                .padding(.horizontal, AuraTheme.Spacing.xxl)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            NeonButton(title: "UNLOCK", icon: "lock.open.fill", color: .neonGold) {
                let success = PremiumManager.shared.validateBetaCode(betaCodeInput)
                if success {
                    showBetaUnlock = false
                    betaCodeInput = ""
                    withAnimation { betaUnlockSuccess = true }
                }
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)

            Spacer()
        }
        .auraBackground()
    }

    // MARK: - Beta Success Banner

    private var betaSuccessBanner: some View {
        VStack {
            Spacer()

            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "crown.fill")
                    .foregroundColor(.neonGold)
                Text("3 mois de Pro débloqués")
                    .font(AuraTheme.Fonts.body())
                    .foregroundColor(.auraTextPrimary)
            }
            .padding(AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.medium)
            .neonGlow(color: .neonGold, radius: 8, cornerRadius: AuraTheme.Radius.medium)
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.bottom, AuraTheme.Spacing.xxl)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { betaUnlockSuccess = false }
            }
        }
    }

    // MARK: - Actions

    private func performDeleteAccount() {
        isDeleting = true
        let vm = SettingsViewModel(context: viewContext)
        vm.deleteAccount()
        isDeleting = false
        deleteComplete = true
    }

    // MARK: - Helpers

    private func formatXP(_ xp: Int64) -> String {
        if xp >= 1000 {
            return String(format: "%.1fk", Double(xp) / 1000.0)
        }
        return "\(xp)"
    }
}

// MARK: - Preview

#Preview {
    ProfileView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
