import SwiftUI

extension View {
    /// Conditionally applies a transformation to the view.
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Hides the view based on a boolean condition.
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    /// Applies the AuraLift dark background to a full-screen view.
    func auraBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.auraBlack.ignoresSafeArea())
    }

    /// Standard section header style for AuraLift.
    func auraSectionHeader() -> some View {
        self
            .font(AuraTheme.Fonts.subheading())
            .foregroundColor(.auraTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AuraTheme.Spacing.lg)
            .padding(.top, AuraTheme.Spacing.xl)
            .padding(.bottom, AuraTheme.Spacing.sm)
    }
}
