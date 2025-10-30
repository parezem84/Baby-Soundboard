//
//  RevenueCatManager.swift
//  MoonNest
//
//  Created by Michal Pařízek on 30.10.2025.
//

import Foundation
import RevenueCat
import SwiftUI

class RevenueCatManager: ObservableObject {
    static let shared = RevenueCatManager()
    
    @Published var isPremium = false
    @Published var currentOffering: Offering?
    @Published var isLoading = false
    
    // Product IDs
    private let monthlyProductID = "moonnest.monthly"
    private let yearlyProductID = "moonnest.yearly"
    
    private init() {
        setupRevenueCat()
    }
    
    private func setupRevenueCat() {
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "app2731b00cda")
        
        // Set up delegate
        Purchases.shared.delegate = self
        
        // Check current subscription status
        checkSubscriptionStatus()
        loadOfferings()
    }
    
    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                if let customerInfo = customerInfo {
                    self?.isPremium = customerInfo.entitlements["premium"]?.isActive == true
                    print("RevenueCat: Premium status = \(self?.isPremium ?? false)")
                } else if let error = error {
                    print("RevenueCat Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func loadOfferings() {
        isLoading = true
        Purchases.shared.getOfferings { [weak self] offerings, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let offerings = offerings {
                    self?.currentOffering = offerings.current
                    print("RevenueCat: Loaded \(offerings.all.count) offerings")
                } else if let error = error {
                    print("RevenueCat Error loading offerings: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func purchaseMonthly() {
        guard let offering = currentOffering,
              let monthlyPackage = offering.monthly else {
            print("RevenueCat: No monthly package available")
            return
        }
        
        purchase(package: monthlyPackage)
    }
    
    func purchaseYearly() {
        guard let offering = currentOffering,
              let yearlyPackage = offering.annual else {
            print("RevenueCat: No yearly package available")
            return
        }
        
        purchase(package: yearlyPackage)
    }
    
    private func purchase(package: Package) {
        isLoading = true
        Purchases.shared.purchase(package: package) { [weak self] transaction, customerInfo, error, userCancelled in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let customerInfo = customerInfo {
                    self?.isPremium = customerInfo.entitlements["premium"]?.isActive == true
                    print("RevenueCat: Purchase successful, premium = \(self?.isPremium ?? false)")
                } else if userCancelled {
                    print("RevenueCat: Purchase cancelled by user")
                } else if let error = error {
                    print("RevenueCat: Purchase error - \(error.localizedDescription)")
                }
            }
        }
    }
    
    func restorePurchases() {
        isLoading = true
        Purchases.shared.restorePurchases { [weak self] customerInfo, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let customerInfo = customerInfo {
                    self?.isPremium = customerInfo.entitlements["premium"]?.isActive == true
                    print("RevenueCat: Restore successful, premium = \(self?.isPremium ?? false)")
                } else if let error = error {
                    print("RevenueCat: Restore error - \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Helper methods for premium feature access
    func canUseTimer() -> Bool {
        return isPremium
    }
    
    func canUseAllSounds() -> Bool {
        return isPremium
    }
    
    // Free vs Premium sound limits
    func getAvailableSounds(from allSounds: [(String, String, String)]) -> [(String, String, String)] {
        if isPremium {
            return allSounds
        } else {
            // Free users get first 5 sounds
            return Array(allSounds.prefix(5))
        }
    }
}

// MARK: - PurchasesDelegate
extension RevenueCatManager: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        DispatchQueue.main.async {
            self.isPremium = customerInfo.entitlements["premium"]?.isActive == true
            print("RevenueCat: Customer info updated, premium = \(self.isPremium)")
        }
    }
}