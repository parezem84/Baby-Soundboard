//
//  AppUserIdentity.swift
//  MoonNest
//
//  A single stable user ID shared between RevenueCat and Superwall, so
//  RevenueCat subscription data can be associated with Superwall paywall
//  events (required by Superwall's RevenueCat integration).
//

import Foundation

enum AppUserIdentity {
    private static let key = "moonnest_app_user_id"

    static let current: String = {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: key)
        return newID
    }()
}
