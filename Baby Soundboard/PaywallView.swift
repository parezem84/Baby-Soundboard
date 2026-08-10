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
    @State private var showRestoreAlert = false
    @State private var restoreAlertMessage = ""
    
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
                Text("Unlock Pro")
                    .font(.appLargeTitle)
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
                
                // Premium features
                VStack(spacing: 24) {
                    PremiumFeatureRow(
                        icon: "music.note.list",
                        title: "20+ Soothing Sounds",
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
                                priceDetail: "",
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
                        Text(selectedPlan == .yearly ? "Start 3-Day Free Trial" : "Continue")
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
                .onChange(of: revenueCat.isPremium) { isPremium in
                    if isPremium {
                        dismiss()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 8)

                // Disclaimer text below CTA
                if let offering = revenueCat.currentOffering {
                    let priceText = selectedPlan == .yearly
                        ? (offering.annual?.storeProduct.localizedPriceString ?? "") + "/year"
                        : (offering.monthly?.storeProduct.localizedPriceString ?? "") + "/month"

                    let disclaimerText = selectedPlan == .yearly
                        ? "3-day free trial, then \(priceText)"
                        : priceText

                    Text(disclaimerText)
                        .font(.appCaption)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }

                Spacer()

                // Privacy Policy, Redeem Code, and Restore at bottom
                HStack(spacing: 16) {
                    Button("Privacy Policy") {
                        if let url = URL(string: "https://intelligent-eel-d04.notion.site/MoonNest-Privacy-Policy-29a86cea7c0a805f8d5ce1eb63f1b649?pvs=74") {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.appCaption)
                    .foregroundColor(.white.opacity(0.7))

                    Button("Redeem Code") {
                        handleRedeemCode()
                    }
                    .font(.appCaption)
                    .foregroundColor(.white.opacity(0.7))

                    Button("Restore") {
                        handleRestore()
                    }
                    .font(.appCaption)
                    .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            revenueCat.loadOfferings()
        }
        .alert("Restore Purchases", isPresented: $showRestoreAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreAlertMessage)
        }
    }

    private func handleRestore() {
        revenueCat.restorePurchases { success, message in
            restoreAlertMessage = message
            showRestoreAlert = true
        }
    }

    private func handleRedeemCode() {
        Purchases.shared.presentCodeRedemptionSheet()
    }

    private func formatMonthlyPrice(from package: Package) -> String {
        let yearlyPrice = package.storeProduct.price as NSDecimalNumber
        let monthlyPrice = yearlyPrice.dividing(by: NSDecimalNumber(value: 12))
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
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

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(price)
                        .font(.appHeadline)
                        .foregroundColor(.white)

                    if !priceDetail.isEmpty {
                        Text(priceDetail)
                            .font(.appCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

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