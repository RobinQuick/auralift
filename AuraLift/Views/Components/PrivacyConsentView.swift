import SwiftUI

/// GDPR privacy consent screen shown before first morpho scan.
/// Explains on-device processing, data collection, and storage.
struct PrivacyConsentView: View {
    let onAccepted: () -> Void
    let onRefused: () -> Void

    // MARK: - Constants

    static let consentKey = "com.aurea.privacyConsentAccepted"

    static var isConsentAccepted: Bool {
        UserDefaults.standard.bool(forKey: consentKey)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: AuraTheme.Spacing.xl) {
                Spacer(minLength: AuraTheme.Spacing.xl)

                // MARK: - Header
                headerSection

                // MARK: - On-Device Badge
                onDeviceBadge

                // MARK: - Info Cards
                collectedCard
                storedCard
                notDoneCard

                // MARK: - Buttons
                buttonSection

                Spacer(minLength: AuraTheme.Spacing.xl)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
        .auraBackground()
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .cyberpunkText(color: .neonBlue)

            Text("CONFIDENTIALITÉ & DONNÉES")
                .font(AuraTheme.Fonts.title())
                .cyberpunkText(color: .neonBlue)
        }
    }

    // MARK: - On-Device Badge

    private var onDeviceBadge: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "iphone")
                .font(.system(size: 16))
                .foregroundColor(.neonGreen)

            Text("ANALYSE ON-DEVICE")
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(.neonGreen)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .padding(.vertical, AuraTheme.Spacing.sm)
        .background(
            Capsule()
                .fill(Color.neonGreen.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.neonGreen.opacity(0.4), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("On-device analysis")
    }

    // MARK: - Info Cards

    private var collectedCard: some View {
        infoCard(
            icon: "list.bullet.clipboard",
            title: "CE QUI EST COLLECTÉ",
            items: [
                "Points squelettiques (19 articulations)",
                "Poids, Taille",
                "Données d'entraînement (séries, vitesse, forme)"
            ],
            accent: .neonBlue
        )
    }

    private var storedCard: some View {
        infoCard(
            icon: "lock.iphone",
            title: "OÙ C'EST STOCKÉ",
            items: [
                "Localement sur votre iPhone",
                "Chiffré par iOS (CoreData + Data Protection)",
                "Jamais synchronisé vers le cloud"
            ],
            accent: .neonGreen
        )
    }

    private var notDoneCard: some View {
        infoCard(
            icon: "xmark.shield.fill",
            title: "CE QUI N'EST PAS FAIT",
            items: [
                "Aucune vidéo ou photo transmise",
                "Aucun serveur externe",
                "Aucune revente de données"
            ],
            accent: .cyberOrange
        )
    }

    private func infoCard(icon: String, title: String, items: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(accent)

                Text(title)
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(accent)
            }

            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: AuraTheme.Spacing.sm) {
                    Circle()
                        .fill(accent.opacity(0.6))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)

                    Text(item)
                        .font(AuraTheme.Fonts.body())
                        .foregroundColor(.auraTextPrimary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .darkCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(items.joined(separator: ". "))")
    }

    // MARK: - Buttons

    private var buttonSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            NeonButton(title: "ACCEPTER ET CONTINUER", icon: "checkmark.shield.fill", color: .neonGreen) {
                UserDefaults.standard.set(true, forKey: Self.consentKey)
                onAccepted()
            }

            NeonOutlineButton(title: "REFUSER", icon: "xmark", color: .neonRed) {
                onRefused()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrivacyConsentView(
        onAccepted: {},
        onRefused: {}
    )
}
