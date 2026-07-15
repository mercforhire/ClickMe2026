//
//  ClickMe2026AppDelegate.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import UIKit

class ClickMe2026AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        StripeConfiguration.configure()
        return true
    }
}
