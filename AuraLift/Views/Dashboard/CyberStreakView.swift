import SwiftUI

// MARK: - CyberStreakView

/// Neon flame streak display with tier, multiplier, and streak freeze button.
struct CyberStreakView: View {
    @ObservedObject private var streakManager = CyberStreakManager.shared
    @State private var showPaywall = false
    @State private var freezeApplied = false

    var body: some View {
        VStack(spacing: AuraTheme.Spacing.xl) {
            // Flame header
            flameDisplay

            // Stats row
            statsRow

            // Multiplier info
            multiplierCard

            // Streak Freeze
            streakFreezeSection

            // Risk alert
            if streakManager.isAtRisk {
                riskAlert
            }

            Spacer(minLength: AuraTheme.Spacing.xxl)
        }
        .padding(.top, AuraTheme.Spacing.lg)
        .auraBackground()
        .navigationTitle("Cyber-Streak")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Flame Display

    private var flameDisplay: some View {
        VStack(spacing: AuraTheme.Spacing.md) {
            ZStack {
                // Glow circle
                Circle()
                    .fill(flameSwiftUIColor.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .shadow(color: flameSwiftUIColor.opacity(0.4), radius: 20)

                Image(systemName: streakManager.streakTier.flameIcon)
                    .font(.system(size: 56))
                    .foregroundColor(flameSwiftUIColor)
                    .shadow(color: flameSwiftUIColor.opacity(0.6), radius: 8)
            }
            .pulse()

            Text("\(streakManager.currentStreak)")
                .font(AuraTheme.Fonts.statValue(48))
                .foregroundColor(flameSwiftUIColor)

            Text("JOURS CONSÉCUTIFS")
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)

            Text(streakManager.streakTier.label.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(.auraBlack)
                .padding(.horizontal, AuraTheme.Spacing.md)
                .padding(.vertical, 4)
                .background(Capsule().fill(flameSwiftUIColor))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streakManager.currentStreak) consecutive days, \(streakManager.streakTier.label) tier")
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AuraTheme.Spacing.md) {
            streakStat(label: "Multiplicateur", value: "x\(String(format: "%.1f", streakManager.xpMultiplier))", color: .neonGold)
            streakStat(label: "Streak", value: "\(streakManager.currentStreak)j", color: flameSwiftUIColor)
            streakStat(label: "Prochain palier", value: nextTierLabel, color: .auraTextSecondary)
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    private func streakStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: AuraTheme.Spacing.xs) {
            Text(value)
                .font(AuraTheme.Fonts.statValue(20))
                .foregroundColor(color)
            Text(label)
                .font(AuraTheme.Fonts.caption())
                .foregroundColor(.auraTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .darkCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value)")
    }

    // MARK: - Multiplier Card

    private var multiplierCard: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            Text("PALIERS DE MULTIPLICATEUR")
                .auraSectionHeader()

            VStack(spacing: AuraTheme.Spacing.xs) {
                multiplierRow(days: "1-2", mult: "x1.0", tier: .spark)
                multiplierRow(days: "3-6", mult: "x1.2", tier: .burning)
                multiplierRow(days: "7-13", mult: "x1.5", tier: .blazing)
                multiplierRow(days: "14-29", mult: "x2.0", tier: .infernal)
                multiplierRow(days: "30+", mult: "x2.5", tier: .mythic)
            }
            .padding(.horizontal, AuraTheme.Spacing.lg)
        }
    }

    private func multiplierRow(days: String, mult: String, tier: StreakTier) -> some View {
        let isActive = streakManager.streakTier == tier
        let tierColor = colorForTier(tier)

        return HStack {
            Circle()
                .fill(tierColor)
                .frame(width: 8, height: 8)

            Text(days + " jours")
                .font(AuraTheme.Fonts.body())
                .foregroundColor(isActive ? .auraTextPrimary : .auraTextSecondary)

            Spacer()

            Text(mult)
                .font(AuraTheme.Fonts.mono())
                .foregroundColor(isActive ? tierColor : .auraTextDisabled)

            if isActive {
                Image(systemName: "arrow.left")
                    .font(.system(size: 10))
                    .foregroundColor(tierColor)
            }
        }
        .padding(.vertical, AuraTheme.Spacing.xs)
        .padding(.horizontal, AuraTheme.Spacing.md)
        .background(isActive ? tierColor.opacity(0.08) : Color.clear)
        .cornerRadius(AuraTheme.Radius.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) days, \(mult) multiplier\(isActive ? ", current tier" : "")")
    }

    // MARK: - Streak Freeze

    private var streakFreezeSection: some View {
        VStack(spacing: AuraTheme.Spacing.sm) {
            HStack(spacing: AuraTheme.Spacing.md) {
                Image(systemName: "snowflake")
                    .font(.system(size: 22))
                    .foregroundColor(.neonBlue)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: AuraTheme.Spacing.xs) {
                        Text("STREAK FREEZE")
                            .font(AuraTheme.Fonts.subheading())
                            .foregroundColor(.auraTextPrimary)

                        PremiumBadge(.small)
                    }

                    Text("Gèle ta flamme 1 fois par mois")
                        .font(AuraTheme.Fonts.caption())
                        .foregroundColor(.auraTextSecondary)
                }

                Spacer()

                if freezeApplied {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.neonGreen)
                        .accessibilityLabel("Streak freeze activated")
                } else if streakManager.freezeAvailable {
                    Button {
                        freezeApplied = streakManager.useStreakFreeze()
                    } label: {
                        Text("ACTIVER")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.auraBlack)
                            .padding(.horizontal, AuraTheme.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.neonBlue))
                    }
                    .accessibilityLabel("Activate streak freeze")
                } else if !PremiumManager.shared.isPro {
                    Button {
                        showPaywall = true
                    } label: {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.neonGold)
                    }
                    .accessibilityLabel("Unlock streak freeze with premium")
                } else {
                    Text("UTILISÉ")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.auraTextDisabled)
                        .accessibilityLabel("Streak freeze already used this month")
                }
            }
            .darkCard()
        }
        .padding(.horizontal, AuraTheme.Spacing.lg)
    }

    // MARK: - Risk Alert

    private var riskAlert: some View {
        HStack(spacing: AuraTheme.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.cyberOrange)

            VStack(alignment: .leading, spacing: 2) {
                Text("ATTENTION")
                    .font(AuraTheme.Fonts.subheading())
                    .foregroundColor(.cyberOrange)

                Text("Ton multiplicateur x\(String(format: "%.1f", streakManager.xpMultiplier)) va disparaître ! Entraîne-toi aujourd'hui.")
                    .font(AuraTheme.Fonts.caption())
                    .foregroundColor(.auraTextSecondary)
            }

            Spacer()
        }
        .padding(AuraTheme.Spacing.md)
        .background(Color.cyberOrange.opacity(0.1))
        .cornerRadius(AuraTheme.Radius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AuraTheme.Radius.medium)
                .stroke(Color.cyberOrange.opacity(0.3), lineWidth: 0.5)
        )
        .padding(.horizontal, AuraTheme.Spacing.lg)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Warning: Your x\(String(format: "%.1f", streakManager.xpMultiplier)) multiplier will be lost. Train today to keep it.")
    }

    // MARK: - Helpers

    private var flameSwiftUIColor: Color {
        switch streakManager.streakTier {
        case .none: return .auraTextDisabled
        case .spark, .burning: return .neonBlue
        case .blazing, .infernal: return .neonPurple
        case .mythic: return .neonGold
        }
    }

    private func colorForTier(_ tier: StreakTier) -> Color {
        switch tier {
        case .none: return .auraTextDisabled
        case .spark, .burning: return .neonBlue
        case .blazing, .infernal: return .neonPurple
        case .mythic: return .neonGold
        }
    }

    private var nextTierLabel: String {
        let days = streakManager.currentStreak
        if days < 3 { return "\(3 - days)j" }
        if days < 7 { return "\(7 - days)j" }
        if days < 14 { return "\(14 - days)j" }
        if days < 30 { return "\(30 - days)j" }
        return "MAX"
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        CyberStreakView()
    }
}
