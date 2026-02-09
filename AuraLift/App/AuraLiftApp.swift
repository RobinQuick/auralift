import SwiftUI
import CoreData

@main
struct AuraLiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            if PersistenceController.storeLoadFailed {
                storeErrorView
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .preferredColorScheme(.dark)
                    .task {
                        await PremiumManager.shared.loadProducts()
                    }
            }
        }
    }

    // MARK: - Error View

    private var storeErrorView: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.aureaAlert)

            Text("Data couldn't be loaded")
                .font(.title2.bold())
                .foregroundColor(.aureaWhite)

            Text("Please try reinstalling the app. If the problem persists, contact support.")
                .font(.body)
                .foregroundColor(.aureaSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.aureaVoid)
        .preferredColorScheme(.dark)
    }
}
