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
            }
        }
    }
}
