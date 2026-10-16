//
//  ClickMe2026AppDelegate.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

class ClickMe2026AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Firebase must be configured before any other Firebase call.
        // Reads `GoogleService-Info.plist` from the app bundle — if that
        // file is missing or has a mismatched bundle id, this crashes
        // in DEBUG (which is what we want; silent misconfig is worse).
        FirebaseApp.configure()

        StripeConfiguration.configure()
        configureSystemChrome()

        // Wire the FCM messaging delegate. `didReceiveRegistrationToken`
        // fires whenever Firebase assigns or rotates the FCM token —
        // typically once on first launch and again on iOS reinstall
        // or backup restore.
        Messaging.messaging().delegate = self

        // Register as the notification-center delegate up front so
        // `willPresent` / `didReceive` fire even if the user is later
        // asked for permission mid-session. Setting this before
        // `requestAuthorization` is required by iOS.
        UNUserNotificationCenter.current().delegate = self

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

    // MARK: - APNs registration callbacks
    //
    // FCM piggybacks on APNs — it can't issue a registration token
    // until iOS gives us a raw APNs token and we hand it to Firebase.
    // We do NOT send the APNs hex to the backend directly; the backend
    // wants the FCM token, delivered via `MessagingDelegate` below.

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        #if DEBUG
        let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
        print("APNs device token registered: \(tokenHex)")
        #endif
        // Forward the raw APNs token to Firebase so it can issue an
        // FCM registration token. FCM decides the environment from
        // the `aps-environment` entitlement (development vs
        // production); no manual override needed.
        Messaging.messaging().apnsToken = deviceToken
    }

    /// Silent failure — logs in debug builds, otherwise the app carries
    /// on. Common causes: no `aps-environment` entitlement,
    /// Simulator without a paired Mac, or a genuine APNs outage.
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        #if DEBUG
        print("push: APNs registration FAILED = \(error.localizedDescription)")
        let ns = error as NSError
        print("push:   domain=\(ns.domain) code=\(ns.code)")
        // Most common cause on-device: `aps-environment` entitlement
        // missing from the provisioning profile (Push Notifications
        // capability not enabled in Xcode / Apple Developer portal).
        // Simulator without a paired Mac is the other common one.
        #endif
    }

    /// Fires on every foreground — cold launch and
    /// background→foreground resume both flow through here (UIKit
    /// calls this after `didFinishLaunching` and after
    /// `willEnterForeground` respectively).
    ///
    /// Re-registers the device's current FCM token with the backend on
    /// every activation. The backend now enforces **one device-token
    /// binding per account** — historically shared test devices ended
    /// up with multiple accounts claiming the same FCM token, and
    /// pushes landed on the wrong account. Re-asserting the binding on
    /// every foreground guarantees whoever's currently logged in owns
    /// the device's token; no-op if not logged in.
    func applicationDidBecomeActive(_ application: UIApplication) {
        Task { @MainActor in
            UserManager.shared.refreshPushTokenBinding()
        }
    }

    // MARK: - MessagingDelegate

    /// FCM issued (or rotated) our registration token. This is the value
    /// the backend sends pushes to via Firebase — different from the
    /// raw APNs token. Uploads via `UserManager.registerPushToken`.
    /// Fires on every launch after `Messaging.apnsToken` is set, so
    /// no manual re-fetch is required.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        #if DEBUG
        print("FCM registration token: \(fcmToken)")
        #endif
        Task { @MainActor in
            await UserManager.shared.registerPushToken(fcmToken)
        }
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Foreground presentation policy. iOS 14+ uses `.banner + .list`
    /// (banner slides down + goes into Notification Center) plus sound
    /// and badge. Without this the app would silently swallow pushes
    /// received while it's frontmost.
    ///
    /// Also bumps `PushRouter.newNotificationTick` so
    /// `NotificationsListView` refreshes if the user is sitting on it.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        if let event = PushEvent(userInfo: userInfo) {
            Task { @MainActor in
                PushRouter.shared.handleForegroundArrival(event)
            }
        }
        completionHandler([.banner, .list, .sound, .badge])
    }

    /// User tapped a notification. Parse the payload and hand off to
    /// the router — the active shell picks up `pendingDestination`
    /// and navigates. Always call the completion handler last so iOS
    /// releases the notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        #if DEBUG
        print("push: TAP received. Full userInfo:")
        for (key, value) in userInfo {
            print("push:   [\(key)] = \(value)")
        }
        #endif
        if let event = PushEvent(userInfo: userInfo) {
            #if DEBUG
            print("push: parsed event — category=\(event.category), sub_category=\(event.subCategory ?? "nil"), booking_id=\(event.bookingId?.uuidString ?? "nil"), thread_id=\(event.threadId?.uuidString ?? "nil")")
            #endif
            Task { @MainActor in
                PushRouter.shared.handleTap(event)
                completionHandler()
            }
        } else {
            #if DEBUG
            print("push: PushEvent parse FAILED — no `category` field found. Backend payload shape mismatch.")
            #endif
            completionHandler()
        }
    }
}
