import SwiftUI
import StoreKit

// MARK: - PaywallView

/// Cyberpunk-styled paywall with 3 product cards (lifetime, yearly, monthly),
/// purchase CTA, social proof, and restore link.
struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaywallViewModel()

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: AuraTheme.Spacing.xl) {
                    headerSection
                    featuresList
                    productCards
                    purchaseButton
                    socialProof
                    restoreLink

                    Spacer(minLength: AuraTheme.Spacing.xxl)
                }
                .padding(.top, AuraTheme.Spacing.xxl)
            }
            .auraBackground()

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.auraTextSecondary)
                    .padding(AuraTheme.Spacing.lg)
            }
        }
        .task {
            await PremiumManager.shared.loadProducts()
            // Pre-select yearly after products load
            if let yearly = viewModel.yearlyProduct {
                viewModel.selectProduct(yearly)
            }
        }
        .onChange(of: viewModel.purchaseSuccess) { _, success in
            if success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .cyberpunkText(color: .neonGold)

            Text("AURALIFT PRO")
                .font(AuraTheme.Fonts.title(32))
                .cyberpunkText(color: .neonGold)

            Text("Libère ton potentiel maximal")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextSecondary)
        }
    }

    // MARK: - Features

    private var featuresList: some View {
        VStack(alignment: .leading, spacing: AuraTheme.Spacing.sm) {
            featureRow(icon: "speedometer", text: "Velocity-Based Training complet")
            featureRow(icon: "figure.stand", text: "Ghost Mode AR coaching")
            featureRow(icon: "waveform", text: "Spartan Warrior voice pack")
            featureRow(icon: "star.circle.fill", text: "Season Pass rewards premium")
            featureRow(icon: "snowflake", text: "Streak Freeze — 1x / mois")
            featureRow(icon: "chart.bar.fill", text: "Statistiques avancées")
        }
        .padding(.horizontal, AuraTheme.Spacing.xl)
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.neonGold)
                .frame(width: 24)

            Text(text)
                .font(AuraTheme.Fonts.body())
                .foregroundColor(.auraTextPrimary)

            Spacer()
        }
    }

    // MARK: - Product Cards

    private var productCards: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            if let lifetime = viewModel.lifetimeProduct {
                productCard(
                    product: lifetime,
                    badge: "FOUNDER STATUS",
                    subtitle: "Paiement unique à vie",
                    accentColor: .neonGold
                )
            }

            if let yearly = viewModel.yearlyProduct {
                productCard(
                    product: yearly,
                    badge: "POPULAIRE",
                    subtitle: "Économise 50%",
                    accentColor: .neonBlue
                )
                .pulse()
            }

            if let monthly = viewModel.monthlyProduct {
                productCard(
                    product: monthly,
                    badge: nil,
                    subtitle: "Flexibilité mensuelle",
                    accentColor: .auraTextSecondary
                )
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func productCard(
        product: Product,
        badge: String?,
        subtitle: String,
        accentColor: Color
    ) -> some View {
        let selected = viewModel.isSelected(product)

        return Button {
            viewModel.selectProduct(product)
        } label: {
            VStack(spacing: AuraTheme.Spacing.sm) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.auraBlack)
                        .padding(.horizontal, AuraTheme.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(accentColor))
                }

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(product.displayName)
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.auraTextPrimary)

                        Text(subtitle)
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(viewModel.priceString(for: product))
                            .font(AuraTheme.Fonts.statValue(22))
                            .foregroundColor(accentColor)

                        Text(viewModel.periodLabel(for: product))
                            .font(AuraTheme.Fonts.caption())
                            .foregroundColor(.auraTextSecondary)
                    }
                }
            }
            .padding(AuraTheme.Spacing.lg)
            .background(Color.auraSurfaceElevated)
            .cornerRadius(AuraTheme.Radius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                    .stroke(selected ? accentColor : accentColor.opacity(0.2), lineWidth: selected ? 2 : 0.5)
            )
            .shadow(color: selected ? accentColor.opacity(0.3) : .clear, radius: 8)
        }
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            if viewModel.purchaseSuccess {
                HStack(spacing: AuraTheme.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.neonGreen)
                    Text("PRO ACTIVÉ")
                        .font(AuraTheme.Fonts.heading())
                        .cyberpunkText(color: .neonGreen)
                }
            } else {
                NeonButton(
                    title: viewModel.isPurchasing ? "TRAITEMENT..." : "DÉBLOQUER LE POTENTIEL",
                    icon: "bolt.fill",
                    color: .neonGold
                ) {
                    Task { await viewModel.purchase() }
                }
                .disabled(viewModel.isPurchasing || viewModel.selectedProduct == nil)
                .padding(.horizontal, AuraTheme.Spacing.lg)
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.neonRed)
            }
        }
    }

    // MARK: - Social Proof

    private var socialProof: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 14))
                .foregroundColor(.neonBlue)

            Text("Rejoins les athlètes de la Saison 0")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
    }

    // MARK: - Restore

    private var restoreLink: some View {
        Button {
            Task { await viewModel.restore() }
        } label: {
            Text("Déjà abonné ? Restaurer")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.neonBlue)
                .underline()
        }
        .disabled(viewModel.isPurchasing)
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
