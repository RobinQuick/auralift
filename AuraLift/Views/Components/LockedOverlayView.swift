import SwiftUI

// MARK: - LockedOverlayView

/// Blur overlay with lock icon and "PRO" text displayed over gated content.
/// Tapping the overlay triggers the paywall.
struct LockedOverlayView: View {
    @Binding var showPaywall: Bool

    var message: String = "PRO"
    var blurRadius: CGFloat = 8

    var body: some View {
        ZStack {
            // Blur layer
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)

            // Lock icon + label
            VStack(spacing: AuraTheme.Spacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.neonGold)

                PremiumBadge(.medium)
            }
        }
        .cornerRadius(AuraTheme.Radius.small)
        .contentShape(Rectangle())
        .onTapGesture {
            showPaywall = true
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Locked premium feature")
        .accessibilityHint("Double tap to view upgrade options")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        VStack {
            Text("Secret Content")
                .font(.title)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 150)
        .background(Color.auraSurfaceElevated)
        .cornerRadius(AuraTheme.Radius.medium)

        LockedOverlayView(showPaywall: .constant(false))
            .frame(width: 200, height: 150)
    }
    .auraBackground()
}
