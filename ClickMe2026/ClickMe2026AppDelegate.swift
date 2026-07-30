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
        configureSystemChrome()
        return true
    }

    /// Pin `UINavigationBar` + `UITabBar` to the app's dark surface so
    /// system chrome never flashes to a light appearance mid-transition
    /// (used to happen during TabView tab switches on tabs whose root
    /// view didn't set its own toolbar background).
    private func configureSystemChrome() {
        let surface = UIColor(red: 0x13 / 255, green: 0x13 / 255, blue: 0x13 / 255, alpha: 1) // #131313

        let navBar = UINavigationBarAppearance()
        navBar.configureWithOpaqueBackground()
        navBar.backgroundColor = surface
        navBar.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = navBar
        UINavigationBar.appearance().compactAppearance = navBar
        UINavigationBar.appearance().scrollEdgeAppearance = navBar

        let tabBar = UITabBarAppearance()
        tabBar.configureWithOpaqueBackground()
        tabBar.backgroundColor = surface
        tabBar.shadowColor = .clear
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }
}
