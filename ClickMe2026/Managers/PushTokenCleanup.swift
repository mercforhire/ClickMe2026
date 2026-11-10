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
/// previous user's pushes.
///
/// A user logout runs the whole cleanup before the session is cleared, in
/// the same order as Android's `UserManager.logout()` (user decision
/// 2026-11-10, quick 261110-mmr, replacing the 02-12 order that routed to
/// Login right after the DELETE): the server DELETE, then Firebase
/// `deleteToken`, then `clearSession()`. The Login screen therefore cannot
/// appear while the cleanup is still running, so the next sign-in can never
/// overlap it (WR-02). Each network step is capped at `timeout` (3 seconds
/// by default, the same cap as Android's `FcmPushTokenRegistrar`), so the
/// worst case is about two timeouts and logout never hangs.
///
/// One `deleteToken` at a time: `signOut`, `forceSignOut` and
/// `retryIfPending` all run their `deleteToken` through one serialized lane
/// (`deleteTokenRun`), and the retry awaits the run in flight before it
/// reads the marker. Because `login` and `signup` await that retry before
/// registering a token, a sign-in that lands while an involuntary logout's
/// background `deleteToken` is still running (the only overlap left) waits
/// for it and then registers against a fresh token; the old cleanup can
/// never start a `deleteToken` after the new account registered. Every wait
/// on the lane goes through `runBounded`, so a hanging Firebase costs the
/// sign-in at most one or two timeouts, never a hang.
///
/// Retry marker (`pendingKey` in UserDefaults, a plain Bool, no secret): set
/// before `deleteToken` and removed only when both steps succeeded, so a
/// kill mid-logout still leaves a retry. The saved retry is
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
/// device evicts the row. Same class of residual when Firebase is
/// unreachable for longer than the cap: the abandoned `deleteToken` may
/// still complete after the next account registered; the regenerated-token
/// callback and the foreground re-upload then re-register the new account.
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

    /// The most recent `deleteToken` run from any of the three entry
    /// points, in flight or finished. The next run on the lane awaits it
    /// before it starts, so two `deleteToken` calls never overlap. `nil`
    /// only until the first run is queued.
    private var deleteTokenRun: Task<Bool, Never>?

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
    /// 2. the retry marker is set, then `deleteToken` (Firebase) runs on the
    ///    lane, cut off after `timeout`; the marker is removed inside that
    ///    run when both network steps succeeded;
    /// 3. `clearSession()` drops the bearer and every other trace of the
    ///    account, and only then does the caller's shell route to Login.
    ///
    /// A failed or timed-out step never stops the later steps: logout always
    /// finishes locally, within about two timeouts.
    func signOut(
        unregister: @escaping @MainActor () async throws -> Void,
        deleteToken: @escaping @MainActor () async throws -> Void,
        clearSession: () -> Void
    ) async {
        let unregistered = await runBounded(unregister)
        defaults.set(true, forKey: Self.pendingKey)
        _ = await enqueueDeleteToken(deleteToken, clearMarkerOnSuccess: unregistered).value
        clearSession()
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
    /// Login at once. `deleteToken` then runs in a background Task on the
    /// lane, bounded by `timeout`, and removes the marker only on success.
    /// Like `signOut`, this keeps no credential (D-18); the deleteToken-only
    /// marker is the whole retry state. A sign-in that lands while this
    /// background run is still going waits for it through `retryIfPending`.
    func forceSignOut(
        deleteToken: @escaping @MainActor () async throws -> Void,
        clearSession: () -> Void
    ) {
        defaults.set(true, forKey: Self.pendingKey)
        clearSession()
        // Enqueued synchronously, so the lane already holds this run when
        // the caller returns: a sign-in that follows at once finds it and
        // waits for it instead of getting ahead of it.
        enqueueDeleteToken(deleteToken, clearMarkerOnSuccess: true)
    }

    // MARK: - Retry at launch and login

    /// Retries the `deleteToken` half of an earlier cleanup that did not
    /// finish (killed mid-logout, offline, Firebase error). Awaits the
    /// `deleteToken` run in flight, if any, before it reads the marker, so
    /// a run that is about to succeed is never doubled and a sign-in that
    /// awaits this call also waits for the old cleanup to finish or time
    /// out. A no-op once the marker is gone. Runs only at launch while
    /// signed out and at the next login or signup before any token is
    /// registered (D-17): the caller awaits it so neither the retry nor an
    /// earlier run can delete the token the new account is about to
    /// register. Never re-sends the server DELETE (D-18): the old bearer is
    /// gone, and the backend evicts the row itself when another account
    /// registers this token or FCM reports it dead on the next send.
    func retryIfPending(deleteToken: @escaping @MainActor () async throws -> Void) async {
        _ = await deleteTokenRun?.value
        guard isPending else { return }
        _ = await enqueueDeleteToken(deleteToken, clearMarkerOnSuccess: true).value
    }

    // MARK: - One deleteToken lane

    /// Queues `work` as the next `deleteToken` on the lane and returns the
    /// run, whose value is whether `work` succeeded. The run awaits the
    /// previous one first (ignoring its result), then runs `work` bounded
    /// by `timeout`, and, when it succeeded and `clearMarkerOnSuccess` is
    /// set, removes the retry marker inside that same run before it
    /// finishes. Clearing the marker inside the run, not in the caller
    /// afterwards, means anyone awaiting the run observes the final marker
    /// state and cannot start a redundant retry.
    ///
    /// Synchronous on purpose: `deleteTokenRun` holds the new run before
    /// this returns, so a caller that cannot await (`forceSignOut`) still
    /// leaves the run where the next `retryIfPending` finds it. A finished
    /// run stays in `deleteTokenRun`; awaiting its value then returns at
    /// once.
    @discardableResult
    private func enqueueDeleteToken(
        _ work: @escaping @MainActor () async throws -> Void,
        clearMarkerOnSuccess: Bool
    ) -> Task<Bool, Never> {
        let previous = deleteTokenRun
        let run = Task { @MainActor [weak self] () -> Bool in
            _ = await previous?.value
            guard let self else { return false }
            let deleted = await runBounded(work)
            if deleted && clearMarkerOnSuccess {
                defaults.removeObject(forKey: Self.pendingKey)
            }
            return deleted
        }
        deleteTokenRun = run
        return run
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
