import Foundation
import StoreKit

// MARK: - StoreKitManager

/// Low-level StoreKit 2 wrapper handling product fetching, purchasing,
/// transaction verification, and entitlement checking.
final class StoreKitManager {

    // MARK: - Product IDs

    enum ProductID: String, CaseIterable {
        case monthly  = "com.auralift.pro.monthly"
        case yearly   = "com.auralift.pro.yearly"
        case lifetime = "com.auralift.pro.lifetime"

        var isSubscription: Bool {
            self != .lifetime
        }
    }

    // MARK: - Singleton

    static let shared = StoreKitManager()

    private var transactionListener: Task<Void, Error>?

    private init() {}

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Fetch Products

    func fetchProducts() async throws -> [Product] {
        let ids = Set(ProductID.allCases.map(\.rawValue))
        let products = try await Product.products(for: ids)
        return products.sorted { lhs, rhs in
            let order: [String: Int] = [
                ProductID.monthly.rawValue: 2,
                ProductID.yearly.rawValue: 1,
                ProductID.lifetime.rawValue: 0
            ]
            return (order[lhs.id] ?? 3) < (order[rhs.id] ?? 3)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerification(verification)
            await transaction.finish()
            return transaction

        case .userCancelled:
            return nil

        case .pending:
            return nil

        @unknown default:
            return nil
        }
    }

    // MARK: - Transaction Listener

    func listenForTransactions() -> Task<Void, Error> {
        let task = Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                do {
                    let transaction = try self.checkVerification(result)
                    await transaction.finish()
                    await MainActor.run {
                        NotificationCenter.default.post(
                            name: .premiumStatusDidChange,
                            object: nil
                        )
                    }
                } catch {
                    // Verification failed — ignore
                }
            }
        }
        transactionListener = task
        return task
    }

    // MARK: - Current Entitlements

    func currentEntitlements() async -> Set<String> {
        var entitled = Set<String>()

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerification(result) else { continue }

            if transaction.revocationDate == nil {
                entitled.insert(transaction.productID)
            }
        }

        return entitled
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
    }

    // MARK: - Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    static let premiumStatusDidChange = Notification.Name("premiumStatusDidChange")
}
