//
//  MoonNestApp.swift
//  MoonNest
//
//  Created by Michal Pařízek on 07.07.2025.
//

import SwiftUI

@main
struct MoonNestApp: App {
    @State private var isLaunchScreenActive = true
    @StateObject private var revenueCat = RevenueCatManager.shared
    
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
