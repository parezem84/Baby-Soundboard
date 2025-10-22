//
//  OnboardingView.swift
//  Baby Soundboard
//
//  Created by Michal Pařízek on 11.07.2025.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var showPaywall = false
    @Binding var isOnboardingComplete: Bool
    
    private let onboardingPages = [
        OnboardingPage(
            title: "30+ calming sounds to help your little one relax and sleep.",
            buttonText: "Continue",
            illustration: .sounds
        ),
        OnboardingPage(
            title: "Set when sounds stop — no need to check the app.",
            buttonText: "Continue",
            illustration: .timer
        ),
        OnboardingPage(
            title: "Sounds keep going, even with your screen off.",
            buttonText: "Get Started",
            illustration: .background
        )
    ]
    
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
                // Page indicator dots at the very top
                HStack(spacing: 8) {
                    ForEach(0..<onboardingPages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.4))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentPage)
                    }
                }
                .padding(.top, 60)
                .padding(.bottom, 40)
                
                // Title under progress bar
                Text(onboardingPages[currentPage].title)
                    .font(.appTitle)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .padding(.horizontal, 32)
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                Spacer()
                
                // Illustration
                OnboardingIllustration(type: onboardingPages[currentPage].illustration)
                    .animation(.easeInOut(duration: 0.5), value: currentPage)
                
                Spacer()
                
                // Continue button at the bottom
                Button(action: {
                    if currentPage < onboardingPages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    } else {
                        // Complete onboarding directly (paywall hidden for v1 launch)
                        completeOnboarding()
                    }
                }) {
                    Text(onboardingPages[currentPage].buttonText)
                        .font(.appHeadline)
                        .foregroundColor(.white)
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
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .animation(.easeInOut(duration: 0.5), value: currentPage)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    // Swipe to next page
                    if value.translation.width < -100 && currentPage < onboardingPages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage += 1
                        }
                    }
                    // Swipe to previous page
                    else if value.translation.width > 100 && currentPage > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentPage -= 1
                        }
                    }
                }
        )
        // Paywall sheet hidden for v1 launch
        // .sheet(isPresented: $showPaywall) {
        //     PaywallView()
        //         .onDisappear {
        //             // Complete onboarding when paywall is dismissed
        //             completeOnboarding()
        //         }
        // }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        withAnimation(.easeInOut(duration: 0.5)) {
            isOnboardingComplete = true
        }
    }
}

struct OnboardingPage {
    let title: String
    let buttonText: String
    let illustration: OnboardingIllustrationType
}

enum OnboardingIllustrationType {
    case sounds
    case timer
    case background
}

struct OnboardingIllustration: View {
    let type: OnboardingIllustrationType
    
    var body: some View {
        switch type {
        case .sounds:
            SoundsIllustration()
        case .timer:
            TimerIllustration()
        case .background:
            BackgroundIllustration()
        }
    }
}

// MARK: - Illustration Components
struct SoundsIllustration: View {
    private let soundIcons = ["rain", "ocean_waves", "wind", "fireplace", "heartbeat", "white_noise"]
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
            
            
            // Sound icons around the outer circle
            ForEach(0..<soundIcons.count, id: \.self) { index in
                let angle = Double(index) * (360.0 / Double(soundIcons.count))
                let radians = angle * .pi / 180
                let radius: CGFloat = 80
                
                VStack(spacing: 0) {
                    Image(soundIcons[index])
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .offset(
                    x: cos(radians) * radius,
                    y: sin(radians) * radius
                )
                .scaleEffect(0.8)
            }
            
            // Center moon icon
            Image(systemName: "moon.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
        .frame(height: 250)
    }
}

struct TimerIllustration: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
            
            // Timer ring
            Circle()
                .trim(from: 0.0, to: isAnimating ? 1.0 : 0.0)
                .stroke(Color.white.opacity(0.8), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: isAnimating)
            
            // Clock icon
            Image(systemName: "clock.fill")
                .font(.system(size: 40))
                .foregroundColor(.white)
        }
        .frame(height: 250)
        .onAppear {
            isAnimating = true
        }
    }
}

struct BackgroundIllustration: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
            
            // Phone outline
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.6), lineWidth: 3)
                .frame(width: 80, height: 120)
            
            // Screen with power icon (screen off)
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.2))
                .frame(width: 70, height: 110)
                .overlay(
                    Image(systemName: "power")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.3)
                )
            
            // Floating music notes
            ForEach(0..<3) { index in
                Image(systemName: "music.note")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .offset(x: CGFloat(60 + index * 20), y: CGFloat(-30 - index * 15))
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .opacity(isAnimating ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: isAnimating)
            }
        }
        .frame(height: 250)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}