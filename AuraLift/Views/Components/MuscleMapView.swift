import SwiftUI

/// Interactive muscle group selector showing a body outline with selectable regions.
struct MuscleMapView: View {
    @Binding var selectedRegion: String?
    var recoveryScores: [String: Double] = [:]

    private let regions: [(name: String, displayName: String, position: CGPoint)] = [
        ("chest_upper", "Chest", CGPoint(x: 0.5, y: 0.22)),
        ("anterior_deltoid", "Shoulders", CGPoint(x: 0.3, y: 0.18)),
        ("biceps_long", "Biceps", CGPoint(x: 0.25, y: 0.32)),
        ("triceps_long", "Triceps", CGPoint(x: 0.75, y: 0.32)),
        ("lats_upper", "Back", CGPoint(x: 0.5, y: 0.32)),
        ("rectus_abdominis", "Abs", CGPoint(x: 0.5, y: 0.42)),
        ("quadriceps", "Quads", CGPoint(x: 0.4, y: 0.58)),
        ("hamstrings", "Hamstrings", CGPoint(x: 0.6, y: 0.58)),
        ("glute_max", "Glutes", CGPoint(x: 0.5, y: 0.5)),
        ("calves", "Calves", CGPoint(x: 0.5, y: 0.75)),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Body silhouette outline
                RoundedRectangle(cornerRadius: AuraTheme.Radius.large)
                    .fill(Color.auraSurfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: AuraTheme.Radius.large)
                            .stroke(Color.auraBorder, lineWidth: 0.5)
                    )

                // Muscle region buttons
                ForEach(regions, id: \.name) { region in
                    let isSelected = selectedRegion == region.name
                    let score = recoveryScores[region.name] ?? 100
                    let color = recoveryColor(for: score)

                    Button {
                        withAnimation(AuraTheme.Animation.quick) {
                            selectedRegion = (selectedRegion == region.name) ? nil : region.name
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Circle()
                                .fill(color.opacity(isSelected ? 0.8 : 0.4))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(isSelected ? color : color.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                                )
                                .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 6)

                            Text(region.displayName)
                                .font(AuraTheme.Fonts.caption(9))
                                .foregroundColor(isSelected ? .auraTextPrimary : .auraTextSecondary)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(region.displayName), \(Int(score)) percent recovered")
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                    .position(
                        x: geo.size.width * region.position.x,
                        y: geo.size.height * region.position.y
                    )
                }
            }
        }
    }

    private func recoveryColor(for score: Double) -> Color {
        if score >= 80 { return .neonGreen }
        if score >= 50 { return .neonGold }
        return .neonRed
    }
}

#Preview {
    MuscleMapView(
        selectedRegion: .constant("quadriceps"),
        recoveryScores: [
            "quadriceps": 45,
            "chest_upper": 90,
            "lats_upper": 70,
            "calves": 20
        ]
    )
    .frame(height: 500)
    .padding()
    .background(Color.auraBlack)
}
