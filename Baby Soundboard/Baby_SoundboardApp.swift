//
//  MoonNestApp.swift
//  MoonNest
//
//  Created by Michal Pařízek on 07.07.2025.
//

import SwiftUI
import SuperwallKit

@main
struct MoonNestApp: App {
    @State private var isLaunchScreenActive = true
    @StateObject private var revenueCat = RevenueCatManager.shared
    private let purchaseController = RCPurchaseController()

    init() {
        // Configure Superwall first so its handshake doesn't wait on RevenueCat/StoreKit,
        // which can hang independently (e.g. AppTransaction fetch issues in sandbox).
        let superwallOptions = SuperwallOptions()
        superwallOptions.logging.level = .debug
        Superwall.configure(
            apiKey: "pk_d9t9BreHch8DduTqt3CbF",
            purchaseController: purchaseController,
            options: superwallOptions
        )
        // Shared ID so RevenueCat subscription data links up with Superwall paywall events.
        Superwall.shared.identify(userId: AppUserIdentity.current)

        RevenueCatManager.shared.configure()
        purchaseController.syncSubscriptionStatus()
    }

    var body: some Scene {
        WindowGroup {
            if isLaunchScreenActive {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isLaunchScreenActive = false
                            }
                        }
                    }
            } else {
                ContentView()
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                        print("🎵 MOONNEST_LOG: App entered background")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        print("🎵 MOONNEST_LOG: App will enter foreground")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        print("🎵 MOONNEST_LOG: App became active")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        print("🎵 MOONNEST_LOG: App will resign active")
                    }
            }
        }
    }
}
