import SwiftUI
import CoreData

@main
struct AuraLiftApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)
                .task {
                    await PremiumManager.shared.loadProducts()
                }
        }
    }
}
