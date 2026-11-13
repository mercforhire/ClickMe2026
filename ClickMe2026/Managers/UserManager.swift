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
    /// `LoginView` shows the alert and clears the flag when it is
    /// dismissed (`clearSuspensionFlag()`), so a later fresh sign-in does
    /// not show it again. In memory only. See
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

    /// Email of the last successful login or signup (trimmed). The
    /// Login screen pre-fills it after any sign-out: Log Out, a forced
    /// logout from a rejected refresh, a suspension, a failed auto-login.
    /// `clearLocalSession()` deliberately keeps it; only account deletion
    /// forgets it (`forgetLastLoginEmail()`). Not a secret but PII, so it
    /// lives in the Keychain (Valet) next to the tokens and never in
    /// UserDefaults or a log. Not observed: Login reads it once when its
    /// view model is created.
    @ObservationIgnored private(set) var lastLoginEmail: String?

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
    /// Valet key for `lastLoginEmail`.
    private let lastLoginEmailKey = "lastLoginEmail"
    /// UserDefaults key for the most recently registered FCM token.
    /// Diagnostic record of what the server has on file for this device;
    /// removed by `clearLocalSession()` so nothing of the old account's
    /// binding survives logout.
    private let pushDeviceTokenKey = "pushDeviceTokenHex"
    /// UserDefaults key for the cached `UserProfileData` snapshot.
    /// Persisted so profile-hub screens render header content (name,
    /// email, avatar) instantly on view mount without waiting for a
    /// network round-trip.
    private let profileCacheKey = "cachedUserProfile"

    private var api: ClickMeAPI { ClickMeAPI.shared }

    /// Ordered, time-bounded push cleanup for logout (PUSH-04): server
    /// DELETE while the bearer is live, then Firebase `deleteToken`, then
    /// the session (Android order), with a credential-free retry marker
    /// (D-17, D-18) and one serialized `deleteToken` lane (WR-02).
    private let pushCleanup = PushTokenCleanup()

    /// `true` from the moment a user logout starts until the session is
    /// cleared, which is the end of the cleanup (about 6 seconds at most:
    /// the DELETE and `deleteToken` are each capped at 3 seconds). While
    /// set, no push token is registered or re-uploaded, so the account that
    /// is logging out cannot re-bind this device while its bearer is still
    /// live, and a second `logout()` is a no-op. The Log out controls read
    /// it to show their in-progress state. It is reset inside
    /// `clearLocalSession()`, so it never outlives the session it protects
    /// and the next sign-in is never blocked by it (WR-02).
    private(set) var isLoggingOut = false

    /// The in-flight deleteToken-only retry started by
    /// `retryPushCleanupIfNeeded()`, so a launch retry and a login retry
    /// that overlap share one run instead of racing Firebase. Cleared when
    /// the run finishes.
    private var pushCleanupRetry: Task<Void, Never>?

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

        // Best-effort read: a missing or unreadable value just means Login
        // opens with an empty email.
        self.lastLoginEmail = try? valet.string(forKey: lastLoginEmailKey)

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
        forceLogout()
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
        // Finish any deleteToken retry owed from an earlier logout BEFORE
        // the new session registers its token, so the retry can never
        // delete the token this account is about to bind (D-17).
        await retryPushCleanupIfNeeded().value
        apply(loginData: response.data)
        rememberLoginEmail(email)
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
        // Same ordering as `login`: the owed deleteToken retry runs before
        // this account's token is registered (D-17).
        await retryPushCleanupIfNeeded().value
        apply(signupData: response.data)
        rememberLoginEmail(email)
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
    ///     in which case stored state is cleared, OR
    ///   - the account is suspended (403 ACCOUNT_SUSPENDED): the suspension
    ///     handler has already cleared the session, and Login shows the
    ///     notice (D-13).
    ///
    /// Rationale: wiping credentials on a transient network blip is a
    /// terrible UX — a user who opens the app in airplane mode would
    /// have to log in again on next online launch, even though their
    /// session is perfectly valid.
    ///
    /// Every launch that stays signed in, including the transient-failure
    /// case, also runs the push permission check. iOS resets notification
    /// permission when the app is deleted and reinstalled, but the
    /// keychain session survives, so this is the only place such a user
    /// is ever asked. A launch that ends logged out never prompts.
    @discardableResult
    func tryAutoLogin() async -> Bool {
        guard hasStoredToken else {
            // Signed-out launch: the only other moment (besides login and
            // signup) the deleteToken-only retry runs (D-17). Not awaited;
            // the splash routes to Login regardless.
            retryPushCleanupIfNeeded()
            return false
        }
        var result = AutoLoginOutcome.RefreshResult.succeeded
        do {
            try await refreshMe()
        } catch {
            // Branch: suspension vs. real auth failure vs. transient
            // network failure.
            if wasSuspended || Self.isSuspension(error) {
                // The suspension handler has already cleared the session
                // and raised `wasSuspended` before the 403 was rethrown;
                // Login reads the flag and shows the notice (D-13).
                result = .suspended
            } else if Self.isAuthRejection(error) {
                // The stored token is dead: no DELETE could succeed with
                // it, so clear at once and kill the FCM token in the
                // background.
                forceLogout()
                result = .authRejected
            } else {
                // Transient — keep the token, synthesize a minimal
                // signed-in state from whatever's cached. `refreshMe` will
                // be retried the next time any screen's `.task` fires a
                // `/me` or any other authed request succeeds, which
                // hydrates `me` for real. Until then the app renders
                // cached profile data.
                result = .transientFailure
            }
        }
        // A suspension resolves to signed out, so the splash routes to
        // Login instead of a home shell with no session (D-13).
        guard AutoLoginOutcome.resolve(hadStoredToken: true, refresh: result) == .signedIn else {
            return false
        }
        if hasStoredToken {
            // Prompts on `.notDetermined` (fresh install, or reinstall),
            // and re-registers when already granted: the OS token can
            // rotate across launches (backup restore, iOS update).
            requestPushPermissionIfNeeded()
            // Same reason as `apply(loginData:)`: Firebase's delegate
            // may have fired before this auto-login completed. Fetch
            // and upload now to close the gap.
            fetchAndUploadFCMToken()
        }
        return true
    }

    /// True when the error is a 403 whose body code is `ACCOUNT_SUSPENDED`.
    /// The global suspension handler has normally run by then; this keeps the
    /// decision correct if the error arrives some other way.
    private static func isSuspension(_ error: Error) -> Bool {
        guard case let NetworkError.httpError(status, data) = error, status == 403 else {
            return false
        }
        let envelope = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        return envelope?.code == .accountSuspended
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

    /// User-initiated logout (Profile → Log out, the delete-account
    /// farewell). Sends `DELETE /notifications/tokens/:device_id` while the
    /// bearer is still valid, then invalidates this install's FCM token,
    /// then clears the session (PUSH-04, D-06 as amended by D-18; the order
    /// is Android's `UserManager.logout()`, user decision 2026-11-10). The
    /// shell routes to Login only once the session is cleared, so the
    /// cleanup is finished by the time Login is visible and a fast re-login
    /// can never overlap it (WR-02). Returns at once; `isLoggingOut` carries
    /// the in-progress state for the Log out controls, and the whole wait is
    /// about 6 seconds at worst because each network step is capped by
    /// `PushTokenCleanup`.
    ///
    /// Also clears the onboarding-shown flag so the next login re-shows the
    /// welcome flow. A second call while a logout is running is a no-op.
    func logout() {
        guard !isLoggingOut else { return }
        isLoggingOut = true
        let deviceId = Self.deviceIdentifier()
        Task { [weak self] in
            guard let self else { return }
            await pushCleanup.signOut(
                unregister: { [weak self] in
                    // Only while the bearer is still set: the DELETE is
                    // authenticated, and with no session there is no row
                    // of ours to remove.
                    guard let self, self.hasStoredToken else { return }
                    _ = try await self.api.unregisterDeviceToken(deviceId: deviceId)
                },
                deleteToken: { try await Messaging.messaging().deleteToken() },
                clearSession: { self.clearLocalSession() }
            )
        }
    }

    /// Involuntary logout: account suspended, stored token rejected at
    /// launch, refresh returned 401 or had no refresh token to try. The
    /// bearer is already dead, so `DELETE /notifications/tokens/:device_id`
    /// would be rejected and is not sent. The session is cleared before this
    /// returns (the shell routes to Login at once) and Firebase `deleteToken`
    /// runs in the background, bounded, leaving the deleteToken-only retry
    /// marker if it fails (D-17, D-18). Safe to call while a user `logout()`
    /// is in flight: `clearLocalSession()` is idempotent.
    private func forceLogout() {
        pushCleanup.forceSignOut(
            deleteToken: { try await Messaging.messaging().deleteToken() },
            clearSession: { self.clearLocalSession() }
        )
    }

    /// Starts, or returns the in-flight, deleteToken-only retry for a
    /// cleanup an earlier logout left unfinished. Called at a signed-out
    /// launch (`tryAutoLogin`) and awaited by `login` / `signup` before the
    /// new session registers a token (D-17). The retry also waits for the
    /// `deleteToken` of an involuntary logout still running in the
    /// background (bounded by the cleanup timeout), so a sign-in inside
    /// that window registers against a fresh token and never races it
    /// (WR-02). Carries no credential (D-18). A no-op run (no marker, no
    /// run in flight) finishes immediately.
    @discardableResult
    private func retryPushCleanupIfNeeded() -> Task<Void, Never> {
        if let pushCleanupRetry { return pushCleanupRetry }
        let retry = Task { [weak self] in
            guard let self else { return }
            await pushCleanup.retryIfPending(
                deleteToken: { try await Messaging.messaging().deleteToken() }
            )
            self.pushCleanupRetry = nil
        }
        pushCleanupRetry = retry
        return retry
    }

    /// Drops every trace of the session on this device: in-memory user
    /// state, the bearer and refresh credentials in the keychain, the
    /// socket, the onboarding, mode and profile cache flags, the cached
    /// push token, any queued push tap and the visible-chat marker. Safe to
    /// call twice: every step is a removal or an assignment of the empty
    /// state, so a logout that overlaps an involuntary one is harmless.
    private func clearLocalSession() {
        // The leaving account has no bearer from here on, so `hasStoredToken`
        // keeps it out of `registerPushToken`; the guard flag is reset in
        // the same step so it never outlives the session it protects. A flag
        // that outlived the clear blocked the next sign-in's registration
        // (WR-02).
        isLoggingOut = false
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
        UserDefaults.standard.removeObject(forKey: pushDeviceTokenKey)
        currentMode = .client
        // A mode request still waiting on its lookup belongs to the old
        // session: replace it so a quick sign-in cannot receive its result.
        modeSwitchGeneration += 1
        setupHubRequested = false
        isSwitchingMode = false
        // "Not now" belongs to the account that chose it; it must not reach
        // the next sign-in on this device (T-05-15).
        setupDeferral.clear()
        // A tap queued for the old account must never route after sign-out,
        // and a chat that was on screen must not suppress the next
        // account's message banners (Android `clearSessionData` parity).
        PushRouter.shared.pending = nil
        ChatPresence.shared.clearSessionData()
    }

    // MARK: - Remembered login email

    /// Stores the trimmed `email` of a successful login / signup. An empty
    /// value is ignored.
    func rememberLoginEmail(_ email: String) {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastLoginEmail = trimmed
        do {
            try valet.setString(trimmed, forKey: lastLoginEmailKey)
        } catch {
            // Intentionally ignored and not logged (the value is PII): a
            // failed Keychain write only loses the pre-fill after the next
            // launch; this session still has it in memory.
        }
    }

    /// The account is gone (deleted): Login must no longer offer its email.
    func forgetLastLoginEmail() {
        lastLoginEmail = nil
        do {
            try valet.removeObject(forKey: lastLoginEmailKey)
        } catch {
            // Intentionally ignored and not logged. The in-memory value is
            // already nil, so this session never pre-fills the deleted
            // account's email. With `.whenUnlocked` accessibility the call
            // fails in practice only while the device is locked, and the
            // user is on screen confirming the deletion.
        }
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

    // MARK: - Expert-mode gate (SIGN-06)

    /// Who asked for a mode switch. A push never opens the setup hub (the
    /// push planner already fails closed on incomplete setup).
    enum ModeSwitchSource {
        case user
        case push
    }

    /// How a `requestModeSwitch` call ended.
    enum ModeSwitchResult: Equatable {
        /// The mode was applied (and persisted).
        case switched(AppMode)
        /// Expert setup is unfinished; Expert was not entered. When the user
        /// asked, `setupHubRequested` is raised for the app shell.
        case setupRequired
        /// The user signed out while the lookup ran; nothing was written.
        case sessionEnded
        /// A newer request replaced this one; nothing was written.
        case superseded
        /// A call is active; nothing was written and no alert was raised.
        case blockedByCall
    }

    /// Set when an Expert switch found the expert's setup unfinished and the
    /// user asked for it. `ClickMe2026App` consumes it (`consumeSetupHubRequest()`)
    /// and routes to the setup hub. Reset by `clearLocalSession()`.
    private(set) var setupHubRequested = false

    /// `true` while an Expert switch waits on its setup lookup. Reset by
    /// `clearLocalSession()`.
    private(set) var isSwitchingMode = false

    /// Identifies the newest mode request so an older one still waiting on
    /// its lookup can tell it was replaced.
    @ObservationIgnored private var modeSwitchGeneration = 0

    /// Whether the expert's setup is finished, or nil when the lookup failed
    /// (offline, server error). Launch, login, the mode switch and the
    /// foreground re-check all use this one helper (plans 05-10 and 05-12), so
    /// they fail open the same way (D-02). The value is read only after the
    /// network call returns; see `ExpertModeGate.setupCompleted(from:)`.
    private func lookUpSetupCompleted() async -> Bool? {
        await ExpertModeGate.setupCompleted(from: {
            try await self.refreshExpertProfile()
            return self.expertProfile?.setupCompleted
        })
    }

    /// The single entry point for switching the app between Client and Expert
    /// (D-03). The decisions are the pure `ExpertModeGate`; this method owns
    /// the state and the lookup.
    ///
    /// An Expert switch is an explicit user choice, so the lookup it makes may
    /// promote a client-only account through the server's `ensureExpert`; that
    /// is accepted as consent (D-04, Android D-23). The setup state comes only
    /// from the lookup: a failed lookup must not fall back to a profile cached
    /// earlier, because Publish leaves that cache saying "unfinished" and the
    /// finished expert would be sent back to the hub (D-02).
    ///
    /// - Parameters:
    ///   - target: The mode to enter.
    ///   - source: Who asked. A push never opens the setup hub.
    @discardableResult
    func requestModeSwitch(_ target: AppMode, source: ModeSwitchSource = .user) async -> ModeSwitchResult {
        // Single-call invariant: no switch, from a user or a push, while a call is active.
        guard !CallCenter.shared.isCallActive else { return .blockedByCall }
        modeSwitchGeneration += 1
        let token = modeSwitchGeneration
        guard target == .expert else {
            isSwitchingMode = false
            setMode(.client)
            return .switched(.client)
        }
        isSwitchingMode = true
        let setupCompleted = await lookUpSetupCompleted()
        let resolution = ExpertModeGate.resolveSwitch(
            isLatestRequest: token == modeSwitchGeneration,
            isLoggedIn: isLoggedIn,
            isCallActive: CallCenter.shared.isCallActive,
            setupCompleted: setupCompleted,
            fromPush: source == .push
        )
        switch resolution {
        case .superseded:
            // The newer request owns `isSwitchingMode`.
            return .superseded
        case .sessionEnded:
            isSwitchingMode = false
            return .sessionEnded
        case .blockedByCall:
            isSwitchingMode = false
            return .blockedByCall
        case .enterExpert:
            isSwitchingMode = false
            setMode(.expert)
            return .switched(.expert)
        case let .setupRequired(opensHub):
            // Expert is not persisted, so a cold launch cannot land on an
            // empty Expert dashboard.
            isSwitchingMode = false
            if opensHub { setupHubRequested = true }
            return .setupRequired
        }
    }

    /// Called by the app shell once it has acted on `setupHubRequested`.
    func consumeSetupHubRequest() {
        setupHubRequested = false
    }

    // MARK: Setup deferral (Not now, D-01)

    /// The persisted "Not now" from the setup hub. Cleared on every sign-out,
    /// by `completeSetup()` and when the user asks for Expert again.
    @ObservationIgnored private let setupDeferral = SetupDeferralStore()

    /// Whether the user chose Not now on the setup hub and has not since
    /// published, asked for Expert again or signed out.
    var isSetupDeferred: Bool { setupDeferral.isDeferred }

    /// The hub's Not now (Android `deferSetup`): remembers the choice, sets
    /// Client mode and drops any pending hub request so the shell does not
    /// reopen the hub.
    func deferSetup() {
        setupDeferral.set()
        setMode(.client)
        setupHubRequested = false
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
            // back to login rather than letting them stew on a 401. The
            // bearer just 401'd, so this is an involuntary logout: no
            // DELETE, session cleared at once, deleteToken in the background.
            forceLogout()
            return false
        }
        do {
            let response = try await api.refreshSession(refreshToken: stored)
            applyRefreshed(response.data)
            return true
        } catch {
            if case NetworkError.httpError(let status, _) = error, status == 401 {
                forceLogout()
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
    /// — safe to call from every login / signup path and from
    /// `tryAutoLogin`. On subsequent launches with a previously-granted
    /// permission, iOS silently hands us a fresh device token via
    /// `AppDelegate.didRegister…`. Users who denied are not asked again.
    ///
    /// Keep this on the cold-launch path and out of
    /// `applicationDidBecomeActive`: dismissing the OS prompt fires
    /// didBecomeActive again.
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

    /// Called by `AppDelegate` (via the `MessagingDelegate` callback) or
    /// `fetchAndUploadFCMToken` with the current FCM registration token.
    /// POSTs to `/notifications/tokens` so the backend can push to this
    /// device via Firebase. Persists the token locally so `logout()`
    /// can DELETE the correct row on the server.
    ///
    /// Returns early, storing nothing, while a user logout is running (the
    /// bearer is live for the whole DELETE and `deleteToken` wait): a token
    /// that arrived mid-logout, including the one Firebase regenerates after
    /// `deleteToken`, must not re-bind this device to the account that is
    /// leaving, and must not survive `clearLocalSession()` in UserDefaults
    /// (PUSH-04). The flag is reset by `clearLocalSession()`, so the next
    /// account's token is never skipped (WR-02).
    func registerPushToken(_ token: String) async {
        guard !isLoggingOut else {
            #if DEBUG
            print("push: registerPushToken skipped — logout in progress")
            #endif
            return
        }
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
    ///
    /// Also returns early while a user logout is running: a foreground
    /// re-upload that lands during the cleanup (the bearer stays live until
    /// the DELETE and `deleteToken` have finished or timed out) would
    /// re-bind the device to the account that is leaving (PUSH-04).
    /// `registerPushToken` repeats the guard for the token the callback
    /// delivers later. Both guards clear with the session, so the next
    /// sign-in's `apply(...)` always registers (WR-02).
    private func fetchAndUploadFCMToken() {
        guard !isLoggingOut else {
            #if DEBUG
            print("push: fetchAndUploadFCMToken skipped — logout in progress")
            #endif
            return
        }
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

    /// Stable per-vendor device id. Same across launches, changes only
    /// when every app from this vendor is uninstalled — good enough
    /// to key APNs registrations against.
    private static func deviceIdentifier() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
