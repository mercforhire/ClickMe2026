//
//  CallCenter.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

/// App-wide, singleton-backed service that owns any in-progress voice
/// call. Lifting the call state up out of any single view lets the
/// call survive tab switches, screen navigations, and screen-to-screen
/// transitions — the user can minimize the call and continue browsing
/// the app.
///
/// Consumers:
/// - **Both shells** (`HomeClientView` / `HomeExpertView`) observe this
///   and render two conditional overlays: the expanded call surface
///   (when `viewModel != nil && !isMinimized`) and the floating pill
///   (when `viewModel != nil && isMinimized`).
/// - **Any surface with a Join Call button** invokes `startCall(…)`
///   instead of presenting a `fullScreenCover(MeetingCallView)` itself.
/// - **Restricted actions** (mode switch, logout, payment methods, …)
///   read `isCallActive` and either hide themselves or divert to a
///   "End the call to change this" alert.
@MainActor
final class CallCenter: ObservableObject {

    static let shared = CallCenter()

    /// The live call VM. Nil when no call is in progress. `MeetingCallView`
    /// consumes this via `@ObservedObject` so the view can be freely
    /// mounted / unmounted (minimize / expand) without tearing down the
    /// Agora session.
    @Published private(set) var viewModel: MeetingCallViewModel?

    /// Toggled by the minimize / expand buttons and by the pill tap.
    /// The two overlays in each shell key off this to decide which of
    /// them to render.
    @Published var isMinimized: Bool = false

    /// Set when a join attempt fails (server refused, bad token, mic
    /// permission denied, etc.). The shell listens and shows a single
    /// alert. Cleared once shown.
    @Published var joinError: String?

    /// Set when the user taps the Chat button on the expanded call
    /// screen. The shell reacts by (1) switching to the Chats tab and
    /// (2) pushing the thread onto that tab's nav stack, then clears
    /// this back to nil. The call itself gets minimized as part of
    /// `requestOpenChatWithPeer()`.
    @Published var pendingChatOpen: PendingChatOpen?

    /// Set by `attempt(_:)` when a restricted action is invoked mid-call.
    /// Bound to a system alert on the shell (via `CallOverlayHost`) so a
    /// single centralized alert covers every restricted surface in the
    /// app — no per-screen alert plumbing required.
    @Published var restrictionAlertMessage: String?

    /// Convenience read for restriction gates elsewhere in the app.
    var isCallActive: Bool { viewModel != nil }

    // MARK: - Restriction gate

    /// One-line guard used by every restricted action across the app.
    /// If a call is active, sets `restrictionAlertMessage` (the shell
    /// pops the alert) and returns `false` — the caller should abort.
    /// Otherwise returns `true` and the caller proceeds as usual.
    ///
    /// Example:
    /// ```swift
    /// Button("Log out") {
    ///     guard CallCenter.shared.attempt("log out") else { return }
    ///     userManager.logout()
    /// }
    /// ```
    @discardableResult
    func attempt(_ actionDescription: String) -> Bool {
        guard isCallActive else { return true }
        restrictionAlertMessage = "End the call to \(actionDescription)."
        return false
    }

    /// Same as `attempt(_:)` but for the specific case where the user is
    /// trying to modify the booking that's currently in progress. Uses
    /// booking-specific copy so the reason is unambiguous. Returns
    /// `false` (and pops the alert) only when the id matches; unrelated
    /// bookings pass through untouched.
    @discardableResult
    func attemptModifyBooking(_ bookingId: UUID, actionDescription: String) -> Bool {
        guard let vm = viewModel, vm.bookingId == bookingId else { return true }
        restrictionAlertMessage = "This session is in progress. End the call to \(actionDescription)."
        return false
    }

    private let api: ClickMeAPI
    private var joinErrorSubscription: AnyCancellable?

    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    // MARK: - Lifecycle

    /// Kick off a new call. No-op when a call is already in progress —
    /// prevents the "two calls at once" edge case even if the caller
    /// forgets to guard on `isCallActive`.
    func startCall(
        bookingId: UUID,
        peerId: UUID,
        peerName: String,
        peerImageURL: String,
        topic: String,
        scheduledStart: Date?,
        scheduledEnd: Date?
    ) {
        // Second-join attempt during an active call — give feedback
        // rather than silently no-op'ing.
        guard viewModel == nil else {
            restrictionAlertMessage = "You're already on a call. End it before starting another."
            return
        }

        let vm = MeetingCallViewModel(
            bookingId: bookingId,
            peerId: peerId,
            expertName: peerName,
            expertImageURL: peerImageURL,
            topic: topic,
            scheduledStart: scheduledStart,
            scheduledEnd: scheduledEnd
        )
        viewModel = vm
        isMinimized = false

        // Bridge the VM's `joinError` into CallCenter so a failed
        // join tears down the whole call container (both overlays
        // disappear) and surfaces the alert on whichever surface
        // launched the call. `dropFirst` skips the initial nil.
        joinErrorSubscription = vm.$joinError
            .dropFirst()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.abortCallOnJoinFailure(message: message)
            }

        // Kick off Agora join immediately — the expanded call view
        // will just observe the resulting `callStatus` transitions.
        vm.startCall()
        vm.ensureTimerRunning()
    }

    /// End the active call and clear all derived state. The VM itself
    /// leaves the Agora channel and POSTs `/bookings/:id/end` via its
    /// own teardown; this method just clears the CallCenter fields
    /// once that finishes so the two overlays disappear.
    func endCall() {
        guard let vm = viewModel else { return }
        vm.handleEndCall { [weak self] in
            guard let self else { return }
            self.viewModel = nil
            self.isMinimized = false
            self.joinErrorSubscription = nil
        }
    }

    /// Force-end synchronously without waiting for Agora teardown. Used
    /// only when `startCall` fails before we ever joined a channel —
    /// there's nothing to leave / POST.
    func abortCallOnJoinFailure(message: String) {
        viewModel = nil
        isMinimized = false
        joinErrorSubscription = nil
        joinError = message
    }

    // MARK: - Minimize / expand

    func minimize() {
        guard viewModel != nil else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            isMinimized = true
        }
    }

    func expand() {
        guard viewModel != nil else { return }
        withAnimation(.easeInOut(duration: 0.28)) {
            isMinimized = false
        }
    }

    // MARK: - Chat shortcut

    /// Tapped from the in-call Chat button. Minimizes the call, looks
    /// up (or creates) the 1:1 thread with the peer, and signals the
    /// shell to jump to the Chats tab + push the thread. Silent on
    /// failure — we surface a joinError-style alert only for the call
    /// itself, not for the chat shortcut.
    func requestOpenChatWithPeer() {
        guard let vm = viewModel, let peerId = vm.peerId else { return }
        let peerName = vm.expertName
        let peerAvatarURL = vm.expertImageURL

        minimize()

        Task { [weak self] in
            guard let self else { return }
            guard let response = try? await self.api.initiateChat(peerId: peerId) else { return }
            self.pendingChatOpen = PendingChatOpen(
                threadId: response.data.threadId,
                peerName: peerName,
                peerAvatarURL: peerAvatarURL
            )
        }
    }

    /// Called by the shell after it consumes `pendingChatOpen` so the
    /// signal doesn't re-fire on the next render.
    func acknowledgeChatOpen() {
        pendingChatOpen = nil
    }
}

/// Payload for the "open chat with peer" signal. `Identifiable` so the
/// shell can use `.onChange(of: pendingChatOpen?.id)` without value
/// equality issues.
struct PendingChatOpen: Identifiable, Equatable {
    let id = UUID()
    let threadId: UUID
    let peerName: String
    let peerAvatarURL: String
}
