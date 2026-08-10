//
//  ReviewManager.swift
//  MoonNest
//
//  Created by Michal Pařízek on 18.11.2025.
//

import Foundation
import StoreKit

class ReviewManager {
    static let shared = ReviewManager()

    private let userDefaults = UserDefaults.standard

    // UserDefaults keys
    private let hasStoppedSoundOnceKey = "hasStoppedSoundOnce"
    private let reviewRequestCountKey = "reviewRequestCount"
    private let lastReviewRequestDateKey = "lastReviewRequestDate"

    private init() {}

    /// Call this method when the user stops a sound (manual or timer)
    func handleSoundStop() {
        let hasStoppedBefore = userDefaults.bool(forKey: hasStoppedSoundOnceKey)

        if !hasStoppedBefore {
            // First time stopping sound - request review immediately
            userDefaults.set(true, forKey: hasStoppedSoundOnceKey)
            requestReview()
        } else {
            // Check if we should ask again based on 30-day interval
            checkAndRequestReviewIfNeeded()
        }
    }

    private func checkAndRequestReviewIfNeeded() {
        let reviewCount = userDefaults.integer(forKey: reviewRequestCountKey)

        // Stop asking after 3 requests (Apple's limit)
        guard reviewCount < 3 else { return }

        // Check if 30 days have passed since last request
        if let lastRequestDate = userDefaults.object(forKey: lastReviewRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0

            if daysSinceLastRequest >= 30 {
                requestReview()
            }
        }
    }

    private func requestReview() {
        // Update tracking data
        let currentCount = userDefaults.integer(forKey: reviewRequestCountKey)
        userDefaults.set(currentCount + 1, forKey: reviewRequestCountKey)
        userDefaults.set(Date(), forKey: lastReviewRequestDateKey)

        // Request review from Apple
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    // For debugging/testing - call this to reset review state
    func resetReviewState() {
        userDefaults.removeObject(forKey: hasStoppedSoundOnceKey)
        userDefaults.removeObject(forKey: reviewRequestCountKey)
        userDefaults.removeObject(forKey: lastReviewRequestDateKey)
    }
}
