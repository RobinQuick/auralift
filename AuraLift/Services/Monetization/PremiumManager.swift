import Foundation
import StoreKit
import Combine

// MARK: - PremiumManager

/// Central authority for premium/Pro status across the app.
/// Combines StoreKit 2 subscriptions, lifetime purchase, and beta unlock
/// into a single `isPro` boolean.
@MainActor
final class PremiumManager: ObservableObject {

    // MARK: - Singleton

    static let shared = PremiumManager()

    // MARK: - Published State

    @Published var isPro: Bool = false
    @Published var availableProducts: [Product] = []
    @Published var activeSubscription: Product? = nil
    @Published var lifetimePurchased: Bool = false
    @Published var betaUnlockActive: Bool = false
    @Published var isLoading: Bool = false

    // MARK: - StoreKit

    private let storeKit = StoreKitManager.shared
    private var transactionTask: Task<Void, Error>?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Keychain Keys

    private static let betaExpiryKey = "com.auralift.betaExpiry"
    private static let betaCode = "ALPHA2026"

    // MARK: - Init

    private init() {
        transactionTask = storeKit.listenForTransactions()
        checkBetaExpiry()

        NotificationCenter.default.publisher(for: .premiumStatusDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.updateStatus()
                }
            }
            .store(in: &cancellables)
    }

    deinit {
        transactionTask?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            availableProducts = try await storeKit.fetchProducts()
        } catch {
            availableProducts = []
        }
        await updateStatus()
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        isLoading = true
        defer { isLoading = false }

        let transaction = try await storeKit.purchase(product)
        guard transaction != nil else { return }
        await updateStatus()
    }

    // MARK: - Restore

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await storeKit.restorePurchases()
        } catch {
            // Restore may fail silently
        }
        await updateStatus()
    }

    // MARK: - Status Update

    func updateStatus() async {
        let entitlements = await storeKit.currentEntitlements()

        // Check lifetime
        lifetimePurchased = entitlements.contains(StoreKitManager.ProductID.lifetime.rawValue)

        // Check active subscription
        activeSubscription = nil
        for product in availableProducts {
            if entitlements.contains(product.id) && product.id != StoreKitManager.ProductID.lifetime.rawValue {
                activeSubscription = product
                break
            }
        }

        // Check beta
        checkBetaExpiry()

        // Unified Pro status
        isPro = activeSubscription != nil || lifetimePurchased || betaUnlockActive
    }

    // MARK: - Beta Code Validation

    func validateBetaCode(_ code: String) -> Bool {
        guard code.uppercased().trimmingCharacters(in: .whitespaces) == Self.betaCode else {
            return false
        }

        // Store 3-month expiry in Keychain
        let expiryDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        let data = withUnsafeBytes(of: expiryDate.timeIntervalSince1970) { Data($0) }
        KeychainHelper.save(key: Self.betaExpiryKey, data: data)

        betaUnlockActive = true
        isPro = true
        return true
    }

    // MARK: - Beta Expiry Check

    func checkBetaExpiry() {
        guard let data = KeychainHelper.read(key: Self.betaExpiryKey),
              data.count == MemoryLayout<TimeInterval>.size else {
            betaUnlockActive = false
            return
        }

        let interval = data.withUnsafeBytes { $0.load(as: TimeInterval.self) }
        let expiryDate = Date(timeIntervalSince1970: interval)
        betaUnlockActive = Date() < expiryDate

        if !betaUnlockActive {
            KeychainHelper.delete(key: Self.betaExpiryKey)
        }
    }

    // MARK: - Product Helpers

    func product(for id: StoreKitManager.ProductID) -> Product? {
        availableProducts.first { $0.id == id.rawValue }
    }

    var monthlyProduct: Product? { product(for: .monthly) }
    var yearlyProduct: Product? { product(for: .yearly) }
    var lifetimeProduct: Product? { product(for: .lifetime) }
}
