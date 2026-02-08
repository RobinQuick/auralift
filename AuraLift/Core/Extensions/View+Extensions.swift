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

    /// Applies the AUREA dark background to a full-screen view.
    func aureaBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.aureaVoid.ignoresSafeArea())
    }

    /// Standard section header style for AUREA.
    func aureaSectionHeader() -> some View {
        self
            .font(AureaTheme.Fonts.subheading())
            .foregroundColor(.aureaTextPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AureaTheme.Spacing.lg)
            .padding(.top, AureaTheme.Spacing.xl)
            .padding(.bottom, AureaTheme.Spacing.sm)
    }

    // MARK: - Legacy Aliases

    func auraBackground() -> some View {
        aureaBackground()
    }

    func auraSectionHeader() -> some View {
        aureaSectionHeader()
    }
}
