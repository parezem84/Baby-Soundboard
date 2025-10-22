//
//  Baby_SoundboardApp.swift
//  Baby Soundboard
//
//  Created by Michal Pařízek on 07.07.2025.
//

import SwiftUI

@main
struct Baby_SoundboardApp: App {
    @State private var isLaunchScreenActive = true
    
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
                        print("🎵 MOONNEST: App entered background")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        print("🎵 MOONNEST: App will enter foreground")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        print("🎵 MOONNEST: App became active")
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                        print("🎵 MOONNEST: App will resign active")
                    }
            }
        }
    }
}
