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

    var isLoggedIn: Bool { me != nil || authUser != nil }

    // MARK: Storage

    private let valet = Valet.valet(
        with: Identifier(nonEmpty: "ClickMe")!,
        accessibility: .whenUnlocked
    )
    private let tokenKey = "authToken"

    private var api: ClickMeAPI { ClickMeAPI.shared }

    // MARK: Init

    private init() {
        if let token = try? valet.string(forKey: tokenKey) {
            api.bearerToken = token
        }
    }

    // MARK: - Login

    /// Authenticates with email + password, persists the JWT, and stores the
    /// returned `AuthUser` snapshot.
    @discardableResult
    func login(email: String, password: String) async throws -> AuthUser {
        let response = try await api.login(email: email, password: password)
        guard let data = response.data else {
            throw URLError(.cannotParseResponse)
        }
        apply(loginData: data)
        return data.user
    }

    private func apply(loginData: LoginData) {
        api.bearerToken = loginData.token
        persist(token: loginData.token)
        authUser = loginData.user
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
    func logout() {
        authUser = nil
        me = nil
        profile = nil
        api.bearerToken = nil
        persist(token: nil)
    }

    // MARK: - Profile fetches

    /// Refreshes the lightweight `/me` snapshot (id, email, role).
    func refreshMe() async throws {
        let response = try await api.getMe()
        me = response.data
    }

    /// Loads the full user profile (`UserProfileData`).
    func refreshProfile() async throws {
        let response = try await api.getUserProfile()
        profile = response.data
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
