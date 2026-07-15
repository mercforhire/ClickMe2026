//
//  AppEnvironment.swift
//  ClickMe2026
//
//  Loaded once at startup from `Environments.plist`. To switch environments,
//  edit the `Current` key in that file (Development / Staging / Production).
//

import Foundation

struct AppEnvironment {
    let name: String
    let baseURL: String
    /// Publishable Stripe key for this environment. Use `pk_test_...` for
    /// Development/Staging, `pk_live_...` for Production. This is the client
    /// half of Stripe's key pair — safe to ship in the app binary.
    let stripePublishableKey: String
    /// Agora RTC App ID for in-app voice calls. Ships in the binary — the
    /// App ID alone isn't sensitive; it's the token minted per session
    /// (returned by `POST /bookings/:id/join`) that grants channel access.
    let agoraAppId: String

    /// The active environment, resolved from `Environments.plist`.
    static let current: AppEnvironment = {
        guard let url = Bundle.main.url(forResource: "Environments", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let root = try? PropertyListSerialization.propertyList(
                  from: data,
                  format: nil
              ) as? [String: Any],
              let currentName = root["Current"] as? String,
              let environments = root["Environments"] as? [String: Any],
              let envDict = environments[currentName] as? [String: Any],
              let baseURL = envDict["BaseURL"] as? String,
              let stripeKey = envDict["StripePublishableKey"] as? String,
              let agoraAppId = envDict["AgoraAppId"] as? String
        else {
            preconditionFailure("Environments.plist is missing or malformed.")
        }
        return AppEnvironment(
            name: currentName,
            baseURL: baseURL,
            stripePublishableKey: stripeKey,
            agoraAppId: agoraAppId
        )
    }()
}
