//
//  PaywallView.swift
//  MoonNest
//
//  Created by Michal Pařízek on 14.07.2025.
//

import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var revenueCat = RevenueCatManager.shared
    @State private var selectedPlan: SubscriptionPlan = .yearly
    
    var body: some View {
        ZStack {
            // Background gradient - same as main app
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#4B0082")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 16)
                    
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // Title
                Text("Unlock Premium")
                    .font(.appLargeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Premium features
                VStack(spacing: 24) {
                    PremiumFeatureRow(
                        icon: "music.note.list",
                        title: "80% More Sounds",
                        description: "Access to all calming sounds in the library"
                    )
                    
                    PremiumFeatureRow(
                        icon: "iphone",
                        title: "Background Audio",
                        description: "Sounds continue playing when screen is off"
                    )
                    
                    PremiumFeatureRow(
                        icon: "timer",
                        title: "Schedule Sound Stop",
                        description: "Set when sounds automatically stop playing"
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                
                Spacer()
                
                // Subscription plans
                VStack(spacing: 12) {
                    if let offering = revenueCat.currentOffering {
                        // Yearly plan
                        if let yearlyPackage = offering.annual {
                            SubscriptionPlanCard(
                                plan: .yearly,
                                title: "Yearly",
                                price: yearlyPackage.storeProduct.localizedPriceString,
                                priceDetail: "\(formatMonthlyPrice(from: yearlyPackage))/month",
                                badge: "BEST VALUE",
                                isSelected: selectedPlan == .yearly
                            ) {
                                selectedPlan = .yearly
                            }
                        }
                        
                        // Monthly plan
                        if let monthlyPackage = offering.monthly {
                            SubscriptionPlanCard(
                                plan: .monthly,
                                title: "Monthly",
                                price: monthlyPackage.storeProduct.localizedPriceString,
                                priceDetail: "per month",
                                badge: nil,
                                isSelected: selectedPlan == .monthly
                            ) {
                                selectedPlan = .monthly
                            }
                        }
                    } else {
                        // Loading state
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 70)
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 70)
                        }
                        .redacted(reason: .placeholder)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
                
                // Subscribe button
                Button(action: {
                    if selectedPlan == .yearly {
                        revenueCat.purchaseYearly()
                    } else {
                        revenueCat.purchaseMonthly()
                    }
                }) {
                    if revenueCat.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                            Text("Processing...")
                                .font(.appHeadline)
                                .foregroundColor(.white)
                        }
                    } else {
                        Text("Start Free Trial")
                            .font(.appHeadline)
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                        )
                )
                .disabled(revenueCat.isLoading || revenueCat.currentOffering == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                
                // Terms and restore
                VStack(spacing: 8) {
                    HStack(spacing: 16) {
                        Button("Terms of Service") {
                            // TODO: Open terms
                        }
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.7))
                        
                        Button("Privacy Policy") {
                            // TODO: Open privacy
                        }
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.7))
                        
                        Button("Restore") {
                            revenueCat.restorePurchases()
                        }
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let offering = revenueCat.currentOffering {
                        let priceText = selectedPlan == .yearly 
                            ? (offering.annual?.storeProduct.localizedPriceString ?? "") + "/year"
                            : (offering.monthly?.storeProduct.localizedPriceString ?? "") + "/month"
                        
                        Text("7-day free trial, then \(priceText)")
                            .font(.appCaption)
                            .foregroundColor(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            revenueCat.loadOfferings()
        }
    }
    
    private func formatMonthlyPrice(from package: Package) -> String {
        let yearlyPrice = package.storeProduct.price
        let monthlyPrice = yearlyPrice.dividing(by: NSDecimalNumber(value: 12))
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = package.storeProduct.priceLocale
        
        return formatter.string(from: monthlyPrice) ?? ""
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.appHeadline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.appSubheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    let title: String
    let price: String
    let priceDetail: String
    let badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.appHeadline)
                            .foregroundColor(.white)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.appCaption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(priceDetail)
                        .font(.appSubheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Text(price)
                    .font(.appTitle)
                    .foregroundColor(.white)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

enum SubscriptionPlan {
    case monthly
    case yearly
}

#Preview {
    PaywallView()
}