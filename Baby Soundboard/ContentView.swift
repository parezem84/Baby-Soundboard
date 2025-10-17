//
//  ContentView.swift
//  Baby Soundboard
//
//  Created by Michal Pařízek on 07.07.2025.
//

import SwiftUI

extension Font {
    static func quicksand(_ weight: QuicksandWeight, size: CGFloat) -> Font {
        return .custom(weight.fontName, size: size)
    }
    
    enum QuicksandWeight {
        case light, regular, medium, semibold, bold
        
        var fontName: String {
            switch self {
            case .light:
                return "Quicksand-Light"
            case .regular:
                return "Quicksand-Regular"
            case .medium:
                return "Quicksand-Medium"
            case .semibold:
                return "Quicksand-SemiBold"
            case .bold:
                return "Quicksand-Bold"
            }
        }
    }
    
    // Default app fonts
    static let appLargeTitle = Font.quicksand(.semibold, size: 28)
    static let appTitle = Font.quicksand(.semibold, size: 28)
    static let appHeadline = Font.quicksand(.semibold, size: 17)
    static let appSubheadline = Font.quicksand(.medium, size: 15)
    static let appBody = Font.quicksand(.regular, size: 17)
    static let appCaption = Font.quicksand(.regular, size: 12)
}

extension Color {
    static let calmBlue = Color(red: 0.235, green: 0.471, blue: 0.847)
    static let calmLightBlue = Color(red: 0.435, green: 0.667, blue: 0.882)
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct ContentView: View {
    @StateObject private var soundPlayer = SoundPlayer()
    @State private var showingSettings = false
    @State private var showingPaywall = false
    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @AppStorage("defaultVolume") private var defaultVolume: Double = 20
    
    private func getSoundDisplayName(_ soundName: String) -> String {
        let soundDict = Dictionary(uniqueKeysWithValues: sounds.map { ($0.0, $0.2) })
        return soundDict[soundName] ?? soundName
    }
    
    let sounds = [
        ("rain", "rain", "Rain"),
        ("white_noise", "white_noise", "White Noise"),
        ("heartbeat", "heartbeat", "Heartbeat"),
        ("ocean_waves", "ocean_waves", "Ocean Waves"),
        ("car_ride", "car_ride", "Car Ride"),
        ("washing_machine", "washing_machine", "Washing Machine"),
        ("fireplace", "fireplace", "Fireplace"),
        ("wind", "wind", "Wind"),
        ("lullaby", "lullaby", "Lullaby"),
        ("birds_chirping", "bird", "Birds Chirping")
    ]
    
    var body: some View {
        Group {
            if isOnboardingComplete {
                mainAppView
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
    }
    
    private var mainAppView: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        ZStack {
                            Text("MoonNest")
                                .font(.appLargeTitle)
                                .foregroundColor(.white)
                            
                            HStack {
                                Button(action: {
                                    showingSettings = true
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                                .padding(.leading, 16)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingPaywall = true
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 14))
                                        Text("Upgrade")
                                            .font(.appCaption)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.orange)
                                    )
                                }
                                .padding(.trailing, 16)
                            }
                        }
                        
                        // Timer countdown display
                        if soundPlayer.timerActive {
                            HStack {
                                Image(systemName: "timer")
                                    .foregroundColor(.white)
                                Text("Stops playing \(getSoundDisplayName(soundPlayer.currentSound ?? "")) in \(soundPlayer.formattedTimeRemaining)")
                                    .font(.appSubheadline)
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Cancel Timer") {
                                    soundPlayer.cancelTimer()
                                }
                                .font(.appCaption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                            ForEach(sounds, id: \.0) { sound in
                                SoundButton(
                                    soundName: sound.0,
                                    emoji: sound.1,
                                    title: sound.2,
                                    isPlaying: soundPlayer.isPlaying && soundPlayer.currentSound == sound.0
                                ) {
                                    soundPlayer.toggleSound(sound.0)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, soundPlayer.isPlaying ? 120 : 20)
                    }
                }
                
                // Floating Control Panel
                if soundPlayer.isPlaying {
                    VStack {
                        Spacer()
                        
                        VStack(spacing: 12) {
                            // Control buttons
                            HStack(spacing: 12) {
                                // Stop button
                                Button(action: {
                                    soundPlayer.stopSound()
                                }) {
                                    Text("Stop")
                                        .font(.appHeadline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 50)
                                }
                                .background(Color.red.opacity(0.8))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                                
                                // Timer menu button
                                Menu {
                                    Button("5 minutes") {
                                        soundPlayer.scheduleStop(after: 5 * 60)
                                    }
                                    Button("10 minutes") {
                                        soundPlayer.scheduleStop(after: 10 * 60)
                                    }
                                    Button("30 minutes") {
                                        soundPlayer.scheduleStop(after: 30 * 60)
                                    }
                                    Button("1 hour") {
                                        soundPlayer.scheduleStop(after: 60 * 60)
                                    }
                                    Button("2 hours") {
                                        soundPlayer.scheduleStop(after: 120 * 60)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "timer")
                                        Text("Timer")
                                        
                                        // Premium badge
                                        HStack(spacing: 2) {
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 8))
                                            Text("PRO")
                                                .font(.system(size: 8, weight: .bold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.orange)
                                        .cornerRadius(4)
                                    }
                                    .font(.appHeadline)
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                }
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#4B0082")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView(soundPlayer: soundPlayer)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .onAppear {
                soundPlayer.setVolume(defaultVolume / 100.0)
            }
        }
    }
}

struct SoundButton: View {
    let soundName: String
    let emoji: String
    let title: String
    let isPlaying: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                VStack(spacing: 12) {
                    Image(emoji)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .foregroundColor(.white)
                    Text(title)
                        .font(.appSubheadline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(
                    isPlaying ? 
                    Color.white.opacity(0.3) : 
                    Color.white.opacity(0.15)
                )
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isPlaying ? 
                            Color.white.opacity(0.6) : 
                            Color.white.opacity(0.2), 
                            lineWidth: 1
                        )
                )
                
                // Play indicator icon - top right corner
                if isPlaying {
                    VStack {
                        HStack {
                            Spacer()
                            Image("sound")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 16, height: 16)
                                .foregroundColor(.white)
                                .padding(.top, 8)
                                .padding(.trailing, 8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .foregroundColor(.white)
        .scaleEffect(isPlaying ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: isPlaying)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var soundPlayer: SoundPlayer
    @AppStorage("defaultVolume") private var defaultVolume: Double = 20
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appHeadline)
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.appLargeTitle)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Done") {
                        dismiss()
                    }
                    .font(.appHeadline)
                    .foregroundColor(.clear)
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                .padding(.horizontal, 16)
                
                // Settings Content
                VStack(spacing: 0) {
                    // Volume Setting
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Default Volume")
                            .font(.appHeadline)
                            .foregroundColor(.white)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("0")
                                    .font(.appCaption)
                                    .foregroundColor(.white.opacity(0.7))
                                Spacer()
                                Text("\(Int(defaultVolume))")
                                    .font(Font.quicksand(.semibold, size: 22))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("100")
                                    .font(.appCaption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Slider(value: $defaultVolume, in: 0...100, step: 1) {
                                Text("Volume")
                            }
                            .accentColor(.white)
                            .onChange(of: defaultVolume) { newValue in
                                soundPlayer.setVolume(newValue / 100.0)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background(
                        Color.white.opacity(0.1)
                            .cornerRadius(16)
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                    
                    // Version number at the bottom
                    VStack(spacing: 8) {
                        Text("Version 0.1")
                            .font(.appCaption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 40)
                }
                .padding(.top, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#87CEEB"), Color(hex: "#4B0082")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ContentView()
}
