import SwiftUI

/// Cyberpunk-styled session stats card rendered to UIImage via ImageRenderer.
/// Fixed 390x520 point frame for consistent sharing output.
struct ShareCardView: View {
    let data: ShareCardData

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Header
            headerSection
                .padding(.top, 24)

            Spacer().frame(height: 20)

            // MARK: - Stats Grid
            statsGrid
                .padding(.horizontal, 20)

            Spacer().frame(height: 16)

            // MARK: - LP Section
            lpSection

            Spacer().frame(height: 12)

            // MARK: - Golden Ratio (if available)
            if let grScore = data.goldenRatioScore, grScore > 0 {
                goldenRatioRow(score: grScore)
                    .padding(.horizontal, 20)
                Spacer().frame(height: 12)
            }

            Spacer()

            // MARK: - Footer
            footerSection
                .padding(.bottom, 16)
        }
        .frame(width: 390, height: 520)
        .background(
            ZStack {
                Color(hex: "000000")

                // Subtle gradient accent
                LinearGradient(
                    colors: [data.tier.color.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(data.tier.color.opacity(0.6), lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text("AURALIFT")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(Color(hex: "00D4FF"))
                    .tracking(4)

                Spacer()

                // Tier badge
                HStack(spacing: 4) {
                    Image(systemName: data.tier.iconName)
                        .font(.system(size: 14))
                    Text(data.tier.displayName.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .foregroundColor(data.tier.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(data.tier.color.opacity(0.15))
                        .overlay(Capsule().stroke(data.tier.color.opacity(0.4), lineWidth: 1))
                )
            }
            .padding(.horizontal, 20)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.username.uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    if !data.exerciseName.isEmpty {
                        Text(data.exerciseName.uppercased())
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(hex: "00D4FF").opacity(0.8))
                    }
                }

                Spacer()

                Text(data.date, style: .date)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statCell(title: "VOLUME", value: String(format: "%.0f kg", data.totalVolume), color: Color(hex: "00D4FF"))
            statCell(title: "SETS", value: "\(data.setsCount)", color: Color(hex: "00D4FF"))
            statCell(title: "FORM", value: "\(Int(data.averageFormScore))%", color: formColor)
            statCell(title: "PEAK VEL", value: String(format: "%.2f m/s", data.peakVelocity), color: Color(hex: "00D4FF"))
        }
    }

    private func statCell(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.5))

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }

    // MARK: - LP Section

    private var lpSection: some View {
        HStack(spacing: 24) {
            VStack(spacing: 2) {
                Text("LP EARNED")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700").opacity(0.7))

                Text("+\(data.lpEarned)")
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundColor(Color(hex: "FFD700"))
                    .shadow(color: Color(hex: "FFD700").opacity(0.5), radius: 8)
            }

            if data.xpEarned > 0 {
                VStack(spacing: 2) {
                    Text("XP EARNED")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(hex: "00D4FF").opacity(0.7))

                    Text("+\(data.xpEarned)")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: "00D4FF"))
                }
            }
        }
    }

    // MARK: - Golden Ratio

    private func goldenRatioRow(score: Double) -> some View {
        HStack {
            Image(systemName: "staroflife.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "FF6B00"))

            Text("GOLDEN RATIO")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "FF6B00"))

            Spacer()

            Text(String(format: "%.0f%%", score))
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(Color(hex: "FF6B00"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "FF6B00").opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: "FF6B00").opacity(0.3), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)

            Text("auralift.app")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color.white.opacity(0.3))

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private var formColor: Color {
        if data.averageFormScore >= 90 { return Color(hex: "00FF88") }
        if data.averageFormScore >= 70 { return Color(hex: "FF6B00") }
        return Color(hex: "FF4444")
    }
}
