//
//  RCPurchaseController.swift
//  MoonNest
//
//  Bridges Superwall's paywall presentation to RevenueCat's purchasing pipeline,
//  so RevenueCat (and the existing "Pro" entitlement) stays the source of truth
//  for subscription state while Superwall controls what the paywall looks like.
//

import Foundation
import SuperwallKit
import RevenueCat
import StoreKit

enum PurchasingError: LocalizedError {
    case sk2ProductNotFound

    var errorDescription: String? {
        switch self {
        case .sk2ProductNotFound:
            return "Superwall didn't pass a StoreKit 2 product to purchase. Are you sure you're not "
                + "configuring Superwall with a SuperwallOption to use StoreKit 1?"
        }
    }
}

final class RCPurchaseController: PurchaseController {
    // Matches the "pro" entitlement identifier configured in the Superwall dashboard.
    private let proEntitlement = Entitlement(id: "pro")

    /// Keeps Superwall's subscription status in sync with RevenueCat's "Pro" entitlement.
    func syncSubscriptionStatus() {
        assert(Purchases.isConfigured, "You must configure RevenueCat before calling this method.")
        Task { [proEntitlement] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                let isPro = customerInfo.entitlements["Pro"]?.isActive == true
                await MainActor.run {
                    Superwall.shared.subscriptionStatus = isPro ? .active([proEntitlement]) : .inactive
                }
            }
        }
    }

    /// Called by Superwall when someone taps a purchase button on a paywall.
    func purchase(product: SuperwallKit.StoreProduct) async -> PurchaseResult {
        do {
            guard let sk2Product = product.sk2Product else {
                throw PurchasingError.sk2ProductNotFound
            }
            let storeProduct = RevenueCat.StoreProduct(sk2Product: sk2Product)
            let revenueCatResult = try await Purchases.shared.purchase(product: storeProduct)
            if revenueCatResult.userCancelled {
                return .cancelled
            } else {
                return .purchased
            }
        } catch let error as ErrorCode {
            if error == .paymentPendingError {
                return .pending
            } else {
                return .failed(error)
            }
        } catch {
            return .failed(error)
        }
    }

    /// Called by Superwall when someone taps "Restore" on a paywall.
    func restorePurchases() async -> RestorationResult {
        do {
            _ = try await Purchases.shared.restorePurchases()
            return .restored
        } catch {
            return .failed(error)
        }
    }
}
