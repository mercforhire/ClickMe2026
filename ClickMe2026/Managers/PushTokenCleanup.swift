//
//  PushTokenCleanup.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Ordered, time-bounded push cleanup for logout (PUSH-04).
///
/// Why the order matters: `DELETE /notifications/tokens/:device_id` needs
/// the account's live bearer, so it has to finish (or be cut off) before the
/// session is cleared. The old `logout()` started it in a Task and dropped
/// the bearer on the next line, so its own signed-in guard always returned
/// early and the DELETE was never sent: a shared device kept getting the
/// previous user's pushes. Firebase `deleteToken` needs no credential, so it
/// runs after the session is gone and the user is already on the login
/// screen.
///
/// Each network step is capped at `timeout` (3 seconds by default, the same
/// cap as Android's `FcmPushTokenRegistrar`): a slow or offline DELETE must
/// not hold up logout, and a hanging `deleteToken` must not hold the
/// `isLoggingOut` guard that blocks the next account's registration.
///
/// Retry marker (`pendingKey` in UserDefaults, a plain Bool, no secret): set
/// before the session is cleared and removed only when both steps succeeded,
/// so a kill mid-logout still leaves a retry. The saved retry is
/// **`deleteToken` only** (D-18, amending D-06): no bearer, refresh token or
/// other credential is kept after logout, so the server DELETE is never
/// re-sent. The backend evicts this token's row when another account
/// registers it (`POST /notifications/tokens`) and deletes rows whose FCM
/// token comes back unregistered on the next send, which is why a
/// credential-free retry is enough.
///
/// The retry runs only at launch (while signed out) and at the next login or
/// signup (D-17). There is no foreground retry. Residual window, accepted by
/// the user under D-17 and D-18: after a logout with no network, in which the
/// DELETE and every `deleteToken` attempt fail, the old account's pushes can
/// arrive on this device until the next launch or login retries the cleanup,
/// FCM reports the token dead on the next push, or another login on this
/// device evicts the row.
///
/// Main-actor bound like the rest of the session code. The steps are
/// injected closures so tests can script order, failures and hangs with no
/// network and no Firebase.
@MainActor
final class PushTokenCleanup {

    /// UserDefaults key for the retry marker. Holds `true` while a cleanup
    /// still has to be retried. Never holds a token or credential.
    static let pendingKey = "pendingPushCleanup"

    private let defaults: UserDefaults
    private let timeout: Duration

    init(defaults: UserDefaults = .standard, timeout: Duration = .seconds(3)) {
        self.defaults = defaults
        self.timeout = timeout
    }

    /// `true` while a `deleteToken` retry is still owed from an earlier
    /// logout whose cleanup did not fully succeed.
    var isPending: Bool {
        defaults.bool(forKey: Self.pendingKey)
    }

    // MARK: - User-initiated logout

    /// Runs the full logout cleanup, in order:
    ///
    /// 1. `unregister` (the server DELETE) while the session is still signed
    ///    in, cut off after `timeout`;
    /// 2. the retry marker is set, then `clearSession()` drops the bearer and
    ///    every other trace of the account;
    /// 3. `deleteToken` (Firebase), cut off after `timeout`.
    ///
    /// The marker is removed only when both network steps succeeded. A
    /// failed or timed-out step never stops the later steps: logout always
    /// finishes locally.
    func signOut(
        unregister: @escaping @MainActor () async throws -> Void,
        deleteToken: @escaping @MainActor () async throws -> Void,
        clearSession: () -> Void
    ) async {
        let unregistered = await runBounded(unregister)
        defaults.set(true, forKey: Self.pendingKey)
        clearSession()
        let deleted = await runBounded(deleteToken)
        if unregistered && deleted {
            defaults.removeObject(forKey: Self.pendingKey)
        }
    }

    // MARK: - Involuntary logout

    /// Cleanup for a logout the user did not ask for: a `403
    /// ACCOUNT_SUSPENDED`, a stored token the server rejects at launch, a
    /// refresh that comes back 401 or has no refresh token to try.
    ///
    /// No server DELETE: the bearer is already dead (or about to be), so the
    /// server would reject it, and nothing would be gained by waiting on it.
    /// The retry marker is set and `clearSession()` runs synchronously, so
    /// the caller returns with the session gone and the shell routes to
    /// Login at once. `deleteToken` then runs in a background Task, bounded
    /// by `timeout`, and removes the marker only on success. Like
    /// `signOut`, this keeps no credential (D-18); the deleteToken-only
    /// marker is the whole retry state.
    func forceSignOut(
        deleteToken: @escaping @MainActor () async throws -> Void,
        clearSession: () -> Void
    ) {
        defaults.set(true, forKey: Self.pendingKey)
        clearSession()
        Task { @MainActor [weak self] in
            guard let self else { return }
            if await runBounded(deleteToken) {
                defaults.removeObject(forKey: Self.pendingKey)
            }
        }
    }

    // MARK: - Retry at launch and login

    /// Retries the `deleteToken` half of an earlier cleanup that did not
    /// finish (killed mid-logout, offline, Firebase error). A no-op without
    /// the marker. Runs only at launch while signed out and at the next
    /// login or signup before any token is registered (D-17): the caller
    /// awaits it so the retry can never delete the token the new account is
    /// about to register. Never re-sends the server DELETE (D-18): the old
    /// bearer is gone, and the backend evicts the row itself when another
    /// account registers this token or FCM reports it dead on the next send.
    func retryIfPending(deleteToken: @escaping @MainActor () async throws -> Void) async {
        guard isPending else { return }
        if await runBounded(deleteToken) {
            defaults.removeObject(forKey: Self.pendingKey)
        }
    }

    // MARK: - Bounded run

    /// Runs `work` and returns whether it finished without throwing within
    /// `timeout`. Returns `false` as soon as the timeout fires, even if
    /// `work` ignores cancellation (a completion-handler bridge such as
    /// Firebase's cannot be interrupted); the abandoned work is cancelled
    /// and its late result is dropped.
    private func runBounded(_ work: @escaping @MainActor () async throws -> Void) async -> Bool {
        await withCheckedContinuation { continuation in
            let race = Race(continuation)
            race.worker = Task { @MainActor in
                let finished: Bool
                do {
                    try await work()
                    finished = true
                } catch {
                    finished = false
                }
                race.finish(finished)
            }
            race.timer = Task { @MainActor [timeout] in
                try? await Task.sleep(for: timeout)
                race.finish(false)
            }
        }
    }

    /// One-shot resumer for the worker-versus-timer race. Whichever side
    /// finishes first resumes the continuation and cancels the other.
    @MainActor
    private final class Race {
        private var continuation: CheckedContinuation<Bool, Never>?
        var worker: Task<Void, Never>?
        var timer: Task<Void, Never>?

        init(_ continuation: CheckedContinuation<Bool, Never>) {
            self.continuation = continuation
        }

        func finish(_ succeeded: Bool) {
            guard let continuation else { return }
            self.continuation = nil
            worker?.cancel()
            timer?.cancel()
            continuation.resume(returning: succeeded)
        }
    }
}
