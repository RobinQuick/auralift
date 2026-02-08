import SwiftUI

/// Custom tab bar with AUREA gold styling.
struct AureaTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, AureaTheme.Spacing.sm)
        .padding(.top, AureaTheme.Spacing.sm)
        .padding(.bottom, AureaTheme.Spacing.xl)
        .background(
            Rectangle()
                .fill(Color.aureaSurface)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [selectedTab.accentColor.opacity(0.1), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(selectedTab.accentColor.opacity(0.3))
                        .frame(height: 0.5)
                }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            withAnimation(AureaTheme.Animation.quick) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: AureaTheme.Spacing.xs) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? tab.accentColor : .aureaTextDisabled)
                    .shadow(
                        color: isSelected ? tab.accentColor.opacity(0.5) : .clear,
                        radius: isSelected ? 6 : 0
                    )

                Text(tab.rawValue)
                    .font(AureaTheme.Fonts.caption(10))
                    .foregroundColor(isSelected ? tab.accentColor : .aureaTextDisabled)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Legacy Alias

typealias CyberpunkTabBar = AureaTabBar

#Preview {
    ZStack(alignment: .bottom) {
        Color.aureaVoid.ignoresSafeArea()
        AureaTabBar(selectedTab: .constant(.dashboard))
    }
}
