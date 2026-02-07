import SwiftUI

/// Custom tab bar with cyberpunk neon styling.
struct CyberpunkTabBar: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, AuraTheme.Spacing.sm)
        .padding(.top, AuraTheme.Spacing.sm)
        .padding(.bottom, AuraTheme.Spacing.xl)
        .background(
            Rectangle()
                .fill(Color.auraSurface)
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
            withAnimation(AuraTheme.Animation.quick) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: AuraTheme.Spacing.xs) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 20, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? tab.accentColor : .auraTextDisabled)
                    .shadow(
                        color: isSelected ? tab.accentColor.opacity(0.5) : .clear,
                        radius: isSelected ? 6 : 0
                    )

                Text(tab.rawValue)
                    .font(AuraTheme.Fonts.caption(10))
                    .foregroundColor(isSelected ? tab.accentColor : .auraTextDisabled)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color.auraBlack.ignoresSafeArea()
        CyberpunkTabBar(selectedTab: .constant(.dashboard))
    }
}
