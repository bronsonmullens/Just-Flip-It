//
//  SubscriptionManager.swift
//  FlippingApp
//
//  Created by Bronson Mullens on 7/13/24.
//

import SwiftUI
import StoreKit

@MainActor
class SubscriptionsManager: NSObject, ObservableObject {
    let productIDs: [String] = ["justflipit.subscription.general", "JFITierOneTip", "JFITierTwoTip"]
    
    var purchasedProductIDs: Set<String> = []
    
    @Published var products: [Product] = []
    
    private var entitlementManager: EntitlementManager? = nil
    private var updates: Task<Void, Never>? = nil
    
    init(entitlementManager: EntitlementManager) {
        self.entitlementManager = entitlementManager
        super.init()
        self.updates = observeTransactionUpdates()
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        updates?.cancel()
    }
    
    func observeTransactionUpdates() -> Task<Void, Never> {
        Task(priority: .background) { [unowned self] in
            for await _ in Transaction.updates {
                await self.updatePurchasedProducts()
            }
        }
    }
}

extension SubscriptionsManager {
    func loadProducts() async {
        do {
            self.products = try await Product.products(for: productIDs)
                .sorted(by: { $0.price > $1.price })
        } catch {
            log.error("Failed to fetch products!")
        }
    }
    
    func buyProduct(_ product: Product) async {
        do {
            let result = try await product.purchase()
            
            switch result {
            case let .success(.verified(transaction)):
                // Successful purhcase
                await transaction.finish()
                await self.updatePurchasedProducts()
            case let .success(.unverified(_, error)):
                // Successful, but receipt can't be confirmed
                log.error("Unverified purchase. Error: \(error)")
                break
            case .pending:
                log.error("Pending purchase. Breaking.")
                break
            case .userCancelled:
                log.error("User cancelled purchase.")
                break
            @unknown default:
                log.error("An unknown error occured.")
                break
            }
        } catch {
            log.error("Failed to purchase the product!")
        }
    }
    
    func updatePurchasedProducts() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }
            if transaction.revocationDate == nil {
                self.purchasedProductIDs.insert(transaction.productID)
            } else {
                self.purchasedProductIDs.remove(transaction.productID)
            }
        }
        
        self.entitlementManager?.hasPro = !self.purchasedProductIDs.isEmpty
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
        } catch {
            log.error("\(error)")
        }
    }
}

extension SubscriptionsManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        return true
    }
}

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "group.bronsonmullens.JFI")!
    
    @AppStorage("hasPremiumSubscription", store: userDefaults)
    var hasPro: Bool = false
}
