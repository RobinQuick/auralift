import Foundation
import StoreKit

// MARK: - PaywallViewModel

/// Drives the paywall purchase flow: product selection, purchase execution,
/// and restore purchases.
@MainActor
final class PaywallViewModel: ObservableObject {

    // MARK: - Published State

    @Published var selectedProduct: Product?
    @Published var isPurchasing: Bool = false
    @Published var purchaseSuccess: Bool = false
    @Published var errorMessage: String?

    // MARK: - Dependencies

    private let premiumManager = PremiumManager.shared

    // MARK: - Computed

    var products: [Product] {
        premiumManager.availableProducts
    }

    var monthlyProduct: Product? { premiumManager.monthlyProduct }
    var yearlyProduct: Product? { premiumManager.yearlyProduct }
    var lifetimeProduct: Product? { premiumManager.lifetimeProduct }

    // MARK: - Init

    init() {
        // Pre-select yearly as default
        selectedProduct = premiumManager.yearlyProduct
    }

    // MARK: - Selection

    func selectProduct(_ product: Product) {
        selectedProduct = product
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = selectedProduct else {
            errorMessage = "Sélectionne un abonnement"
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            try await premiumManager.purchase(product)
            if premiumManager.isPro {
                purchaseSuccess = true
            }
        } catch {
            errorMessage = "Erreur d'achat. Réessaie."
        }

        isPurchasing = false
    }

    // MARK: - Restore

    func restore() async {
        isPurchasing = true
        errorMessage = nil
        await premiumManager.restorePurchases()

        if premiumManager.isPro {
            purchaseSuccess = true
        } else {
            errorMessage = "Aucun achat trouvé"
        }
        isPurchasing = false
    }

    // MARK: - Product Info Helpers

    func priceString(for product: Product) -> String {
        product.displayPrice
    }

    func periodLabel(for product: Product) -> String {
        if product.id == StoreKitManager.ProductID.lifetime.rawValue {
            return "une fois"
        }
        guard let subscription = product.subscription else { return "" }
        switch subscription.subscriptionPeriod.unit {
        case .month: return "/mois"
        case .year: return "/an"
        default: return ""
        }
    }

    func isSelected(_ product: Product) -> Bool {
        selectedProduct?.id == product.id
    }
}
