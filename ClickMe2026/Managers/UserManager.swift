//
//  UserManager.swift
//  ClickMe
//
//  Created by Leon Chen on 2024-01-02.
//  Rewritten 2026-06-21 for ClickMeAPI / JWT auth.
//

import Foundation
import Valet

@MainActor
final class UserManager: ObservableObject {

    static let shared = UserManager()

    // MARK: Published state

    @Published private(set) var authUser: AuthUser?
    @Published private(set) var me: MeData?
    @Published private(set) var profile: UserProfileData?
    /// Expert-scoped profile from `GET /expert/profile`. Carries the
    /// `setup_completed` flag and the rehydration payload for the
    /// mid-flow signup resume path. `nil` for clients and until first
    /// fetch succeeds.
    @Published private(set) var expertProfile: ExpertProfileData?

    /// Which home screen the app should render. Distinct from `role`
    /// (an immutable server-side attribute) — this reflects the user's
    /// current choice via `ModeSwitchView`, or the app's default landing
    /// decision on first entry (a fresh expert with 0 topics lands here
    /// as `.client` until they publish at least one topic). Persisted so
    /// the switch survives cold launches.
    @Published private(set) var currentMode: AppMode

    var isLoggedIn: Bool { me != nil || authUser != nil }

    // MARK: Storage

    private let valet = Valet.valet(
        with: Identifier(nonEmpty: "ClickMe")!,
        accessibility: .whenUnlocked
    )
    private let tokenKey = "authToken"
    private let onboardingShownKey = "hasSeenOnboarding"
    private let currentModeKey = "currentMode"
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
        authUser = loginData.user
        RealtimeService.shared.connect(token: loginData.token)
    }

    // MARK: - Signup

    /// Creates a new account and stashes the bearer token immediately so
    /// subsequent onboarding calls (`uploadAvatar`, `setupExpertProfile`) are
    /// authorized even before the verification email is opened.
    @discardableResult
    func signup(username: String, email: String, password: String, role: UserRole) async throws -> SignupResponse {
        let request = SignupRequest(username: username, email: email, password: password, role: role.rawValue)
        let response = try await api.signup(request)
        apply(signupData: response.data)
        return response.data
    }

    private func apply(signupData: SignupResponse) {
        api.bearerToken = signupData.token
        persist(token: signupData.token)
        RealtimeService.shared.connect(token: signupData.token)
        authUser = signupData.user
    }

    // MARK: - Auto-login

    /// Attempts to restore a session from the persisted token. Returns `true`
    /// when `/me` succeeds, `false` when no token exists or the token is
    /// rejected (in which case stored state is cleared).
    @discardableResult
    func tryAutoLogin() async -> Bool {
        guard hasStoredToken else { return false }
        do {
            try await refreshMe()
            return true
        } catch {
            logout()
            return false
        }
    }

    var hasStoredToken: Bool { api.bearerToken != nil }

    // MARK: - Logout

    /// Clears all in-memory state and the persisted token. Purely client-side.
    /// Also clears the onboarding-shown flag so the next login re-shows the
    /// welcome flow.
    func logout() {
        authUser = nil
        me = nil
        profile = nil
        expertProfile = nil
        api.bearerToken = nil
        persist(token: nil)
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
}
