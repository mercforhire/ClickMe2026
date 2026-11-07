//
//  UserManager.swift
//  ClickMe
//
//  Created by Leon Chen on 2024-01-02.
//  Rewritten 2026-06-21 for ClickMeAPI / JWT auth.
//

import Foundation
import Observation
import UIKit
import UserNotifications
import Valet
import FirebaseMessaging

@MainActor
@Observable
final class UserManager {

    @MainActor static let shared = UserManager()

    // MARK: Observable state

    private(set) var authUser: AuthUser?
    private(set) var me: MeData?
    private(set) var profile: UserProfileData?

    /// Set to `true` when the networking layer observes a
    /// `403 ACCOUNT_SUSPENDED`. Observed by the shell's splash/login
    /// route to present a "Your account has been suspended" message
    /// (with support contact) one shot after the logout settles.
    /// Cleared on the next successful login. See
    /// `docs/ios/USER-REPORTING.md` §4.
    private(set) var wasSuspended: Bool = false
    /// Expert-scoped profile from `GET /expert/profile`. Carries the
    /// `setup_completed` flag and the rehydration payload for the
    /// mid-flow signup resume path. `nil` for clients and until first
    /// fetch succeeds.
    private(set) var expertProfile: ExpertProfileData?

    /// Which home screen the app should render. Distinct from `role`
    /// (an immutable server-side attribute) — this reflects the user's
    /// current choice via `ModeSwitchView`, or the app's default landing
    /// decision on first entry (a fresh expert with 0 topics lands here
    /// as `.client` until they publish at least one topic). Persisted so
    /// the switch survives cold launches.
    private(set) var currentMode: AppMode

    var isLoggedIn: Bool { me != nil || authUser != nil }

    // MARK: Storage

    private let valet = Valet.valet(
        with: Identifier(nonEmpty: "ClickMe")!,
        accessibility: .whenUnlocked
    )
    private let tokenKey = "authToken"
    /// Long-lived rotating credential (see `LoginData.refreshToken`).
    /// Persisted alongside the access token so cold launches can
    /// silently re-authenticate via `/auth/refresh`.
    private let refreshTokenKey = "refreshToken"
    /// Access-token expiry (unix epoch seconds, stored as a string).
    /// Not consumed by the current reactive-only interceptor, but
    /// persisted for the future proactive-refresh path.
    private let tokenExpiresAtKey = "tokenExpiresAt"
    private let onboardingShownKey = "hasSeenOnboarding"
    private let currentModeKey = "currentMode"
    /// UserDefaults key for the most recently registered APNs device
    /// token (hex). Persisted so `logout()` can DELETE the same token
    /// the server has on record, even if iOS hasn't re-issued one this
    /// launch.
    private let pushDeviceTokenKey = "pushDeviceTokenHex"
    /// UserDefaults key for the cached `UserProfileData` snapshot.
    /// Persisted so profile-hub screens render header content (name,
    /// email, avatar) instantly on view mount without waiting for a
    /// network round-trip.
    private let profileCacheKey = "cachedUserProfile"

    private var api: ClickMeAPI { ClickMeAPI.shared }

    /// Codec pair for the on-disk profile cache. Uses default (camelCase)
    /// key coding — we control both encode and decode, so no need for
    /// the API layer's snake-case conversion here.
    private static let cacheEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private static let cacheDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    // MARK: Init

    private init() {
        // Restore the last-chosen mode BEFORE touching `api` (which is a
        // computed prop that requires all stored props initialized).
        // Default to `.client` for a fresh install so a returning expert
        // who never picked a mode lands on the safer default (client
        // home always works; expert home requires at least one topic to
        // be useful).
        let stored = UserDefaults.standard.string(forKey: currentModeKey)
        self.currentMode = (stored == "expert") ? .expert : .client

        // Restore the cached user profile so downstream screens (profile
        // hub, edit-profile) can render header content immediately on
        // launch. `refreshProfile()` still runs on their `.task` to
        // revalidate against the server.
        if let data = UserDefaults.standard.data(forKey: profileCacheKey),
           let cached = try? Self.cacheDecoder.decode(UserProfileData.self, from: data)
        {
            self.profile = cached
        }

        if let token = try? valet.string(forKey: tokenKey) {
            api.bearerToken = token
            RealtimeService.shared.connect(token: token)
        }

        // Wire the network layer's 401 interceptor to this manager.
        // When any authed request 401s, `NetworkService` asks this
        // closure to swap tokens; on success it retries once with the
        // new bearer. `[weak self]` — singleton in practice, weak
        // here just to avoid a self-referential retain when the type
        // is used from tests.
        api.service.authTokenRefresher = TokenRefresher { [weak self] in
            await self?.performRefreshCycle() ?? false
        }

        // Global ACCOUNT_SUSPENDED handler. Fires on ANY 403 whose body
        // code is `ACCOUNT_SUSPENDED`. We clear credentials + disconnect
        // the socket and raise `wasSuspended` so the login/splash view
        // can show the one-shot message. Original error still propagates
        // to the caller.
        api.service.suspensionHandler = { [weak self] in
            self?.handleAccountSuspended()
        }
    }

    @MainActor
    private func handleAccountSuspended() {
        // No-op if we've already handled it (concurrent requests all
        // return 403 at once).
        guard !wasSuspended else { return }
        wasSuspended = true
        logout()
    }

    /// Called by the login/splash view after it has shown the
    /// "account suspended" alert, so a subsequent fresh login doesn't
    /// immediately re-trigger the alert.
    func clearSuspensionFlag() {
        wasSuspended = false
    }

    // MARK: - Login

    /// Authenticates with email + password, persists the JWT, and stores the
    /// returned `AuthUser` snapshot.
    @discardableResult
    func login(email: String, password: String) async throws -> AuthUser {
        let response = try await api.login(email: email, password: password)
        apply(loginData: response.data)
        return response.data.user
    }

    private func apply(loginData: LoginData) {
        api.bearerToken = loginData.token
        persist(token: loginData.token)
        persist(refreshToken: loginData.refreshToken, expiresAt: loginData.expiresAt)
        authUser = loginData.user
        RealtimeService.shared.connect(token: loginData.token)
        // Now that we have a bearer, ask for push permission and (if
        // granted) register the device with APNs. First-time users see
        // the OS prompt; repeat logins are silent because iOS caches
        // the answer.
        requestPushPermissionIfNeeded()
        // Firebase caches the FCM token across launches. Its delegate
        // fires exactly once at launch — often BEFORE this login lands.
        // Actively fetch the current token now so we're guaranteed to
        // upload it under the fresh bearer, closing the logout → login
        // → no-push-token gap.
        fetchAndUploadFCMToken()
    }

    // MARK: - Signup

    /// Creates a new account and stashes the bearer token immediately so
    /// subsequent onboarding calls (`uploadAvatar`, `setupExpertProfile`) are
    /// authorized even before the verification email is opened.
    @discardableResult
    func signup(email: String, password: String, role: UserRole) async throws -> SignupResponse {
        let request = SignupRequest(
            email: email,
            password: password,
            role: role.rawValue
        )
        let response = try await api.signup(request)
        apply(signupData: response.data)
        return response.data
    }

    private func apply(signupData: SignupResponse) {
        api.bearerToken = signupData.token
        persist(token: signupData.token)
        persist(refreshToken: signupData.refreshToken, expiresAt: signupData.expiresAt)
        RealtimeService.shared.connect(token: signupData.token)
        authUser = signupData.user
        requestPushPermissionIfNeeded()
        fetchAndUploadFCMToken()
    }

    // MARK: - Auto-login

    /// Attempts to restore a session from the persisted token. Returns `true`
    /// when `/me` succeeds OR when `/me` fails for transient reasons
    /// (offline, DNS, server 5xx) while a token is still stored — the
    /// user stays signed in and the app lands on home with whatever
    /// cached data is on disk. Returns `false` only when:
    ///   - no token exists in the keychain, OR
    ///   - the stored token is actually rejected (401 / 403 non-suspension),
    ///     in which case stored state is cleared.
    ///
    /// Rationale: wiping credentials on a transient network blip is a
    /// terrible UX — a user who opens the app in airplane mode would
    /// have to log in again on next online launch, even though their
    /// session is perfectly valid.
    @discardableResult
    func tryAutoLogin() async -> Bool {
        guard hasStoredToken else { return false }
        do {
            try await refreshMe()
            // If the user has previously granted push, silently refresh
            // the APNs token — the OS token can rotate across launches
            // (backup restore, iOS update), so we re-upload every time.
            // If they've denied or never been asked, this is a no-op.
            reRegisterPushIfAuthorized()
            // Same reason as `apply(loginData:)`: Firebase's delegate
            // may have fired before this auto-login completed. Fetch
            // and upload now to close the gap.
            fetchAndUploadFCMToken()
            return true
        } catch {
            // Branch: real auth failure vs. transient network failure.
            if Self.isAuthRejection(error) {
                logout()
                return false
            }
            // Transient — keep the token, synthesize a minimal signed-in
            // state from whatever's cached. `refreshMe` will be retried
            // the next time any screen's `.task` fires a `/me` or any
            // other authed request succeeds, which hydrates `me` for
            // real. Until then the app renders cached profile data.
            return true
        }
    }

    /// True when the error is a hard credential rejection (401 or non-
    /// suspension 403), i.e. the stored token is actually invalid and
    /// we should clear it. Network errors, 5xx server errors, timeouts,
    /// and ACCOUNT_SUSPENDED (handled elsewhere) all return false so
    /// `tryAutoLogin` keeps the user signed in.
    private static func isAuthRejection(_ error: Error) -> Bool {
        guard case let NetworkError.httpError(status, data) = error else {
            return false
        }
        if status == 401 { return true }
        if status == 403 {
            // ACCOUNT_SUSPENDED is handled by the global suspension
            // interceptor — don't treat it as a password-is-wrong style
            // rejection here.
            let envelope = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
            if envelope?.code == .accountSuspended { return false }
            return true
        }
        return false
    }

    var hasStoredToken: Bool { api.bearerToken != nil }

    // MARK: - Logout

    /// Clears all in-memory state and the persisted token. Purely client-side.
    /// Also clears the onboarding-shown flag so the next login re-shows the
    /// welcome flow.
    func logout() {
        // Unregister the device from push BEFORE we drop the bearer —
        // otherwise the DELETE call 401s and this account keeps
        // receiving pushes on this device forever. Best-effort; if the
        // server refuses, still tear down the local session.
        Task { [weak self] in await self?.unregisterPushTokenIfAny() }

        authUser = nil
        me = nil
        profile = nil
        expertProfile = nil
        api.bearerToken = nil
        persist(token: nil)
        clearRefreshCredentials()
        RealtimeService.shared.disconnect()
        UserDefaults.standard.removeObject(forKey: onboardingShownKey)
        UserDefaults.standard.removeObject(forKey: currentModeKey)
        UserDefaults.standard.removeObject(forKey: profileCacheKey)
        currentMode = .client
    }

    // MARK: - Onboarding flag

    /// Whether the client-home onboarding modal has been shown to this
    /// account in this session. Reset by `logout()`.
    var hasSeenOnboarding: Bool {
        UserDefaults.standard.bool(forKey: onboardingShownKey)
    }

    func markOnboardingShown() {
        UserDefaults.standard.set(true, forKey: onboardingShownKey)
    }

    /// Clears the flag without logging out. Wired to the hidden 5-tap gesture
    /// on the version footer in profile settings.
    func resetOnboardingShown() {
        UserDefaults.standard.removeObject(forKey: onboardingShownKey)
    }

    // MARK: - Profile fetches

    /// Refreshes the lightweight `/me` snapshot (id, email, role).
    func refreshMe() async throws {
        let response = try await api.getMe()
        me = response.data
    }

    /// Loads the full user profile (`UserProfileData`) and mirrors it to
    /// the on-disk cache so the next cold launch renders header content
    /// (name, email, avatar) without waiting for a network round-trip.
    func refreshProfile() async throws {
        let response = try await api.getUserProfile()
        profile = response.data
        persistProfileCache(response.data)
    }

    private func persistProfileCache(_ data: UserProfileData) {
        guard let encoded = try? Self.cacheEncoder.encode(data) else { return }
        UserDefaults.standard.set(encoded, forKey: profileCacheKey)
    }

    /// Loads the expert-scoped profile (`ExpertProfileData`). Used by the
    /// splash + login gates to check `setup_completed` and by the signup
    /// resume flow to rehydrate the accumulator.
    func refreshExpertProfile() async throws {
        let response = try await api.getExpertProfile()
        expertProfile = response.data
    }

    // MARK: - Mode

    /// Sets the active home mode and persists so it survives cold
    /// launches. Reactive callers observe `currentMode` to snap between
    /// the client and expert home routes.
    func setMode(_ mode: AppMode) {
        currentMode = mode
        UserDefaults.standard.set(mode == .expert ? "expert" : "client", forKey: currentModeKey)
    }

    /// Whether a mode was persisted for the current login. Distinct from
    /// reading `currentMode` — the in-memory value defaults to `.client`
    /// on a fresh install, so callers who need to know "did the user
    /// explicitly choose last time?" (e.g. splash landing decision) must
    /// consult UserDefaults directly. Cleared by `logout()` so a fresh
    /// login always sees `false` on first boot.
    var hasStoredModePreference: Bool {
        UserDefaults.standard.string(forKey: currentModeKey) != nil
    }

    /// True when the expert has at least one topic. Drives the "first
    /// launch → client mode" fallback: a fresh expert who hasn't
    /// published a topic yet lands on client home even though their
    /// role is `.expert`.
    ///
    /// On network failure we default to `false` (safe fallback → client
    /// home) — an established expert briefly landing on client home on
    /// a flaky network is a milder failure than an unsetup expert
    /// landing on an empty expert dashboard.
    func expertHasTopics() async -> Bool {
        do {
            let response = try await api.getMyTopics()
            return !response.data.topics.isEmpty
        } catch {
            return false
        }
    }

    // MARK: - Helpers

    private func persist(token: String?) {
        if let token {
            try? valet.setString(token, forKey: tokenKey)
        } else {
            try? valet.removeObject(forKey: tokenKey)
        }
    }

    // MARK: - Refresh token storage

    /// Persist the rotating refresh token and access-token expiry.
    /// Both are wiped by `clearRefreshCredentials()` on logout or on
    /// a fatal refresh failure. `expiresAt` is stored as a stringified
    /// unix-epoch **seconds** value so the entire auth bundle stays in
    /// Valet rather than split across UserDefaults.
    private func persist(refreshToken: String, expiresAt: Int) {
        try? valet.setString(refreshToken, forKey: refreshTokenKey)
        try? valet.setString(String(expiresAt), forKey: tokenExpiresAtKey)
    }

    private func clearRefreshCredentials() {
        try? valet.removeObject(forKey: refreshTokenKey)
        try? valet.removeObject(forKey: tokenExpiresAtKey)
    }

    private func storedRefreshToken() -> String? {
        try? valet.string(forKey: refreshTokenKey)
    }

    // MARK: - Refresh cycle

    /// Called by `NetworkService`'s 401 interceptor (via
    /// `TokenRefresher`). Reads the stored refresh token, calls
    /// `/auth/refresh`, and stores the rotated pair. Returns `true`
    /// only when the interceptor should retry the original request.
    ///
    /// On a 401 from the refresh endpoint the session is unrecoverable
    /// — we log out here so the app snaps to login rather than leaving
    /// the caller stranded in a retry loop. Any other error
    /// (network / 429 / decoding) fails soft: we return `false`, the
    /// original 401 propagates to the caller, and the stored refresh
    /// token stays intact for the next attempt.
    fileprivate func performRefreshCycle() async -> Bool {
        guard let stored = storedRefreshToken() else {
            // No refresh token on disk — nothing to try. Push the user
            // back to login rather than letting them stew on a 401.
            logout()
            return false
        }
        do {
            let response = try await api.refreshSession(refreshToken: stored)
            applyRefreshed(response.data)
            return true
        } catch {
            if case NetworkError.httpError(let status, _) = error, status == 401 {
                logout()
            }
            return false
        }
    }

    /// Swap the in-memory bearer token and persist the rotated
    /// refresh credential. Also re-arms the realtime socket with the
    /// new access token — the old one will start returning 401s the
    /// moment the server rotates it.
    private func applyRefreshed(_ data: RefreshTokenData) {
        api.bearerToken = data.token
        persist(token: data.token)
        persist(refreshToken: data.refreshToken, expiresAt: data.expiresAt)
        RealtimeService.shared.connect(token: data.token)
    }

    // MARK: - Push notifications

    /// Fires the OS permission prompt if the user hasn't answered yet,
    /// and calls `registerForRemoteNotifications()` on grant. Idempotent
    /// — safe to call from every login / signup path. On subsequent
    /// launches with a previously-granted permission, iOS silently
    /// hands us a fresh device token via `AppDelegate.didRegister…`.
    func requestPushPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            #if DEBUG
            print("push: authorization status = \(Self.describe(settings.authorizationStatus))")
            #endif
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
                    #if DEBUG
                    if let error {
                        print("push: requestAuthorization error = \(error.localizedDescription)")
                    }
                    print("push: user \(granted ? "GRANTED" : "DENIED") notification permission")
                    #endif
                    guard granted else { return }
                    DispatchQueue.main.async {
                        #if DEBUG
                        print("push: calling registerForRemoteNotifications() after grant")
                        #endif
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    #if DEBUG
                    print("push: permission already granted — calling registerForRemoteNotifications()")
                    #endif
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .denied:
                #if DEBUG
                print("push: DENIED at OS level — user must enable in Settings → Notifications → ClickMe")
                #endif
                break
            @unknown default:
                break
            }
        }
    }

    #if DEBUG
    /// Human-readable name for `UNAuthorizationStatus`. Used only for
    /// diagnostic logs.
    private static func describe(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "notDetermined"
        case .denied:        return "denied"
        case .authorized:    return "authorized"
        case .provisional:   return "provisional"
        case .ephemeral:     return "ephemeral"
        @unknown default:    return "unknown"
        }
    }
    #endif

    /// Same as above but silent when the user hasn't answered yet
    /// (never triggers the prompt). Used by `tryAutoLogin` to refresh
    /// the token on cold start without pestering users who declined.
    private func reRegisterPushIfAuthorized() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            default:
                break
            }
        }
    }

    /// Called by `AppDelegate` (via the `MessagingDelegate` callback) or
    /// `fetchAndUploadFCMToken` with the current FCM registration token.
    /// POSTs to `/notifications/tokens` so the backend can push to this
    /// device via Firebase. Persists the token locally so `logout()`
    /// can DELETE the correct row on the server.
    func registerPushToken(_ token: String) async {
        UserDefaults.standard.set(token, forKey: pushDeviceTokenKey)
        guard hasStoredToken else {
            #if DEBUG
            print("push: registerPushToken skipped — no bearer yet (will retry after login)")
            #endif
            return
        }
        let deviceId = Self.deviceIdentifier()
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        #if DEBUG
        print("push: POST /notifications/tokens { device_id: \(deviceId), token: \(token.prefix(24))…, platform: ios }")
        #endif
        do {
            _ = try await api.registerDeviceToken(
                deviceId: deviceId,
                token: token,
                platform: "ios",
                appVersion: appVersion
            )
            #if DEBUG
            print("push: /notifications/tokens SUCCESS")
            #endif
        } catch {
            #if DEBUG
            print("push: /notifications/tokens FAILED = \(error.localizedDescription)")
            #endif
        }
    }

    /// Force an immediate re-fetch + re-upload of the current FCM
    /// registration token. Called from `applicationDidBecomeActive` on
    /// every foreground (cold launch AND background→foreground) so the
    /// backend's one-token-per-account binding always reflects the
    /// currently-logged-in user.
    ///
    /// Motivation: on shared test devices, multiple accounts had
    /// historically ended up sharing the same FCM token binding server
    /// side — pushes could land on the wrong account. Backend now
    /// enforces one binding per token (whoever POSTs last wins), so
    /// this re-upload guarantees "whoever's currently logged in owns
    /// the device's FCM token."
    ///
    /// No-op when not logged in (the underlying `registerPushToken`
    /// guards on `hasStoredToken`) and when APNs hasn't delivered a
    /// token yet (the underlying `fetchAndUploadFCMToken` guards on
    /// `Messaging.apnsToken`).
    func refreshPushTokenBinding() {
        fetchAndUploadFCMToken()
    }

    /// Actively fetch the current FCM registration token from Firebase
    /// and hand it to `registerPushToken`. Called from three places:
    /// 1. `apply(loginData:)` / `apply(signupData:)` — closes the race
    ///    where Firebase's `MessagingDelegate` fires before login lands.
    /// 2. `tryAutoLogin()` — same reason on cold-launch restore.
    /// 3. `refreshPushTokenBinding()` — every foreground, so a shared
    ///    device re-asserts the current account's ownership of the
    ///    token (one binding per token, backend-side).
    ///
    /// Guarded on `Messaging.apnsToken` because Firebase refuses to
    /// issue a token until iOS has delivered the raw APNs token — on
    /// first-ever launch (no cached APNs) we'd get a
    /// `Declining request for FCM Token since no APNS Token specified`
    /// log otherwise. That path is instead handled by the
    /// `MessagingDelegate` firing naturally once APNs registration
    /// completes.
    private func fetchAndUploadFCMToken() {
        guard Messaging.messaging().apnsToken != nil else {
            #if DEBUG
            print("push: fetchAndUploadFCMToken — apnsToken not set yet, waiting for MessagingDelegate")
            #endif
            return
        }
        #if DEBUG
        print("push: fetchAndUploadFCMToken — apnsToken present, fetching FCM token…")
        #endif
        Messaging.messaging().token { [weak self] token, error in
            if let error {
                #if DEBUG
                print("push: Messaging.token failed = \(error.localizedDescription)")
                #endif
                return
            }
            guard let self, let token else {
                #if DEBUG
                print("push: Messaging.token returned nil")
                #endif
                return
            }
            #if DEBUG
            print("push: got FCM token via explicit fetch = \(token.prefix(24))…")
            #endif
            Task { await self.registerPushToken(token) }
        }
    }

    /// Called during `logout()` (fire-and-forget). No-op when there's
    /// no cached token or no bearer to authorize the DELETE.
    private func unregisterPushTokenIfAny() async {
        guard hasStoredToken else { return }
        let deviceId = Self.deviceIdentifier()
        _ = try? await api.unregisterDeviceToken(deviceId: deviceId)
        UserDefaults.standard.removeObject(forKey: pushDeviceTokenKey)
    }

    /// Stable per-vendor device id. Same across launches, changes only
    /// when every app from this vendor is uninstalled — good enough
    /// to key APNs registrations against.
    private static func deviceIdentifier() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
