import SwiftUI

/// Root navigation container with cyberpunk-styled tab bar.
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            Group {
                switch selectedTab {
                case .dashboard:
                    DashboardView()
                case .workout:
                    WorkoutLiveView(context: viewContext)
                case .ranking:
                    RankingView()
                case .recovery:
                    RecoveryHeatmapView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Custom tab bar
            CyberpunkTabBar(selectedTab: $selectedTab)
        }
        .background(Color.auraBlack.ignoresSafeArea())
    }
}

/// App navigation tabs
enum AppTab: String, CaseIterable {
    case dashboard = "Dashboard"
    case workout = "Session"
    case ranking = "Ranking"
    case recovery = "Recovery"
    case profile = "Profile"

    var iconName: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .workout:   return "figure.strengthtraining.traditional"
        case .ranking:   return "trophy.fill"
        case .recovery:  return "heart.fill"
        case .profile:   return "person.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .dashboard: return .aureaPrimary
        case .workout:   return .aureaSecondary
        case .ranking:   return .aureaPrestige
        case .recovery:  return .aureaSuccess
        case .profile:   return .aureaMystic
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
