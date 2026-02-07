import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Seed exercise data on first launch
        let context = PersistenceController.shared.container.viewContext
        SeedDataLoader.loadIfNeeded(into: context)
        return true
    }
}
