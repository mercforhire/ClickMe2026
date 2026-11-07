//
//  MeetingCallViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class MeetingCallViewModel: ObservableObject {

    // MARK: Identity

    /// Booking id — nil in the preview / design path (VM simulates the
    /// 6-second connecting → active transition without any network or
    /// Agora calls).
    let bookingId: UUID?

    /// The peer's user UUID — the expert on client-side calls, the
    /// client on expert-side calls. Used to look up (or create) the
    /// 1:1 chat thread when the in-call Chat button is tapped. Nil in
    /// preview / design init.
    let peerId: UUID?

    /// True when the local user tapped Join on a booking that was
    /// already `completed` server-side (someone hung up early, but the
    /// scheduled end hasn't passed → the row is rejoinable). Two
    /// lifecycle endpoints skip themselves in this mode per the
    /// backend spec:
    ///
    /// - `PATCH /confirm-connection` — the booking is already
    ///   `completed`, so this call would 409 `INVALID_STATUS`.
    /// - `POST /end` — same reason; there's no valid transition.
    ///
    /// The `POST /join` call itself is unconditional — the server is
    /// permissive on rejoin, re-mints a fresh Agora token, and lets
    /// the user drop into the same channel.
    let isRejoin: Bool

    // MARK: Content
    @Published var expertName: String
    @Published var expertImageURL: String
    /// Current user's own avatar URL, sourced from
    /// `UserManager.shared.profile?.personalDetails.avatarUrl`. Renders
    /// alongside the peer avatar once the call is `.active` so it's
    /// visually clear that both people are on this call.
    @Published var myAvatarURL: String
    /// Topic of the session — shown as a subtitle under the peer name.
    @Published var topic: String
    /// Scheduled start / end from the booking. Drive the:
    /// - elapsed timer (`elapsedSeconds` counts from `scheduledStart`),
    /// - "5 min remaining" soft warning, and
    /// - the post-scheduled-end "time is up" banner (call keeps going).
    @Published var scheduledStart: Date?
    @Published var scheduledEnd: Date?

    // MARK: Call state
    @Published var callStatus: CallStatus
    /// Whole seconds elapsed since `scheduledStart` when set, otherwise
    /// since the local join. Ticks every second while the call is
    /// active. May be negative briefly if the user joined slightly
    /// before the scheduled start.
    @Published var elapsedSeconds: Int
    @Published var isMuted: Bool
    @Published var isSpeakerOn: Bool
    @Published var isEndingCall: Bool

    /// Non-fatal error surfaced from the join flow (server error, wrong
    /// meeting type, etc.). `CallCenter` picks it up and forwards to
    /// the generic shell alert. Does NOT fire for mic-permission
    /// denials — those use `micPermissionDenied` so the shell can show
    /// a dedicated alert with an Open Settings button.
    @Published var joinError: String?

    /// Set when join bailed because `AVCaptureDevice.authorizationStatus(
    /// for: .audio)` is `.denied`. `CallCenter` observes this to tear
    /// down the call container AND surface a dedicated alert with a
    /// deep-link to iOS Settings so the user can re-grant the
    /// permission. Separate from `joinError` so the shell can show
    /// different UX for a recoverable permission problem vs a hard
    /// server failure.
    @Published var micPermissionDenied: Bool = false

    // MARK: External-meeting (Skype/Zoom) state

    /// Wire connection type returned by `POST /join`. Nil until the
    /// response resolves; the view uses this to pick between the Agora
    /// audio UI and the Skype/Zoom "open external link" UI.
    @Published var connectionType: ConnectionType?

    /// External meeting URL for `skype_zoom` sessions. Nil for
    /// `in_app_voice` and while the join is still in flight.
    @Published var externalJoinURL: URL?

    /// Flipped `true` when the user taps "Open in Skype/Zoom" on the
    /// external-meeting variant. Drives the status line ("Meeting in
    /// progress" vs "Open the link to start"). Also gates the
    /// `confirm-connection` call for the Skype path — we only fire it
    /// once the user has genuinely engaged with the external meeting.
    @Published var hasOpenedExternalLink: Bool = false

    /// Transient "Link copied" toast — cleared after ~1.5s. Rendered
    /// as a small chip near the Copy button so the user has confirmation
    /// that the pasteboard write succeeded.
    @Published var showLinkCopiedToast: Bool = false

    // MARK: Avatar pulse animation
    @Published var ringPulse: Bool
    @Published var glowPulse: Bool
    /// Flipped when the server pushes `call.ended` for this booking —
    /// i.e. the peer hung up. The view watches it and runs the same
    /// end-call teardown the local Hang Up button would.
    @Published var peerEndedCall: Bool = false

    // MARK: Dependencies

    let agora: AgoraManager
    private let api: ClickMeAPI

    // MARK: Internals

    private var timer: Timer?
    private var joinStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    /// Auto-cancels on VM deallocation.
    private var callEndedSubscription: RealtimeSubscription?

    /// Guards `PATCH /bookings/:id/confirm-connection` so we fire it
    /// at most once per call, even if the Agora state briefly re-enters
    /// `(.ready, .ready)` (rejoin, brief drop + recover, etc.). Flipping
    /// this locally is enough — the server also 409s on a second
    /// attempt because the row is no longer `confirmed`.
    private var hasConfirmedConnection: Bool = false

    // MARK: - Runtime init

    /// Runtime init — POSTs `/bookings/:id/join`, initializes the Agora
    /// engine, and joins the returned channel. Mic/speaker toggles route
    /// to `AgoraManager`. Ending the call leaves the channel and POSTs
    /// `/bookings/:id/end`. `peerId` is the other party's user UUID —
    /// needed to look up the chat thread when the in-call Chat button
    /// is tapped.
    init(
        bookingId: UUID,
        peerId: UUID,
        expertName: String,
        expertImageURL: String,
        topic: String = "",
        scheduledStart: Date? = nil,
        scheduledEnd: Date? = nil,
        initialConnectionType: ConnectionType? = nil,
        isRejoin: Bool = false,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.peerId = peerId
        self.expertName = expertName
        self.expertImageURL = expertImageURL
        self.topic = topic
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.isRejoin = isRejoin
        // Client-side hint from the booking's `meeting_type` — lets
        // the view render the right variant (Agora vs. Skype) the
        // moment Join Call is tapped, instead of flashing the Agora
        // "Connecting…" UI until the join response settles the type.
        // The value is overwritten by `startCall()` with the server's
        // canonical response, so this is only a starting position.
        self.connectionType = initialConnectionType
        // Snapshot at init — profile refreshes elsewhere would clobber
        // a live @Published here anyway, and the call screen is short-
        // lived so a snapshot is fine.
        self.myAvatarURL = UserManager.shared.profile?.personalDetails.avatarUrl ?? ""
        self.callStatus = .connecting
        self.elapsedSeconds = 0
        self.isMuted = false
        self.isSpeakerOn = true
        self.isEndingCall = false
        self.ringPulse = false
        self.glowPulse = false
        self.agora = AgoraManager()
        self.api = api
        wireAgoraStateSync()

        // Peer hang-up / server-side call termination arrives as a
        // `call.ended` socket event. Match on booking id so a stray
        // event from an unrelated call in the same account (e.g.
        // multi-device) doesn't tear ours down.
        let targetId = bookingId
        self.callEndedSubscription = RealtimeService.shared.onCallEnded { [weak self] event in
            guard event.bookingId == targetId else { return }
            Task { @MainActor in self?.peerEndedCall = true }
        }
    }

    // MARK: - Preview / design init

    init(
        expertName: String = "Sophia Carter",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        myAvatarURL: String = "https://randomuser.me/api/portraits/men/32.jpg",
        topic: String = "Advanced Product Strategy Review",
        scheduledStart: Date? = Date().addingTimeInterval(-120),
        scheduledEnd: Date? = Date().addingTimeInterval(30 * 60 - 120),
        callStatus: CallStatus = .connecting,
        elapsedSeconds: Int = 0,
        isMuted: Bool = false,
        isSpeakerOn: Bool = false,
        isEndingCall: Bool = false,
        ringPulse: Bool = false,
        glowPulse: Bool = false
    ) {
        self.bookingId = nil
        self.peerId = nil
        self.isRejoin = false
        self.expertName = expertName
        self.expertImageURL = expertImageURL
        self.myAvatarURL = myAvatarURL
        self.topic = topic
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
        self.callStatus = callStatus
        self.elapsedSeconds = elapsedSeconds
        self.isMuted = isMuted
        self.isSpeakerOn = isSpeakerOn
        self.isEndingCall = isEndingCall
        self.ringPulse = ringPulse
        self.glowPulse = glowPulse
        self.agora = AgoraManager()
        self.api = .shared
    }

    /// Combine `AgoraManager.myConnectionState` and `remoteConnectionState`
    /// into a single `callStatus` the view can render:
    ///
    /// - `.connecting`      — local side not yet in the channel.
    /// - `.waitingForPeer`  — local side joined, peer hasn't arrived.
    /// - `.active`          — both parties in the channel.
    /// - `.ended`           — either side disconnected mid-call.
    ///
    /// Watching both sides is what lets the screen say "you're
    /// connected, waiting for the other person" instead of the
    /// misleading "connecting…" that the old single-signal wiring showed
    /// once the local join succeeded but the peer hadn't shown up yet.
    private func wireAgoraStateSync() {
        Publishers.CombineLatest(
            agora.$myConnectionState,
            agora.$remoteConnectionState
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (mine, remote) in
            guard let self else { return }
            guard self.callStatus != .ended else { return }

            switch (mine, remote) {
            case (.disconnected, _):
                // Local side dropped — genuinely terminal; run teardown.
                self.callStatus = .ended

            case (_, .disconnected):
                // Peer left the channel. Do NOT tear down — let the
                // local user stay on the screen so they can wait for
                // the peer to come back or hang up manually. If the
                // peer rejoins, Agora's `didJoinedOfUid` flips
                // `remoteConnectionState` back to `.ready` and this
                // switch will restore `.active`.
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.callStatus = .waitingForPeer
                }

            case (.ready, .ready):
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.callStatus = .active
                }
                // Both sides are on the Agora channel — signal the
                // backend so it transitions the booking to
                // `in_progress`. Without this, `POST /end` refuses to
                // mark the booking `completed` later, and the cron
                // job sweeps it to `missed`.
                self.confirmConnectionOnce()

            case (.ready, .waiting):
                // We're in, peer isn't. Distinct state so the label
                // doesn't lie about who's holding things up.
                withAnimation(.easeInOut(duration: 0.35)) {
                    self.callStatus = .waitingForPeer
                }

            case (.waiting, _):
                self.callStatus = .connecting
            }
        }
        .store(in: &cancellables)
    }

    // MARK: Derived

    /// `MM:SS` once the scheduled start has passed. Before then (user
    /// joined early), shows a `"Starts in M:SS"` countdown so the label
    /// is meaningful instead of a frozen `00:00` that looks broken.
    var timerString: String {
        if elapsedSeconds < 0 {
            let remaining = -elapsedSeconds
            let m = remaining / 60
            let s = remaining % 60
            return String(format: "Starts in %d:%02d", m, s)
        }
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    /// Seconds remaining until `scheduledEnd`, or `nil` when the
    /// scheduled end isn't known. Negative once we're past the scheduled
    /// end — the call continues (soft ending), the view just shows an
    /// "overtime" banner.
    var remainingSeconds: Int? {
        guard let end = scheduledEnd else { return nil }
        return Int(end.timeIntervalSinceNow)
    }

    /// True when there are between 1 second and 5 minutes left. Drives
    /// the amber "ending soon" banner + tinted timer color.
    var isInFinalStretch: Bool {
        guard let remaining = remainingSeconds else { return false }
        return remaining > 0 && remaining <= 5 * 60
    }

    /// True once we've crossed `scheduledEnd` (call keeps going).
    /// Drives the "scheduled time complete" banner.
    var isPastScheduledEnd: Bool {
        guard let remaining = remainingSeconds else { return false }
        return remaining <= 0
    }

    /// `"5:00 left"` while inside the final-stretch window. Nil
    /// otherwise so the view can hide the chip.
    var remainingLabel: String? {
        guard isInFinalStretch, let remaining = remainingSeconds else { return nil }
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%d:%02d left", m, s)
    }

    /// `"10:30 AM – 11:00 AM"` when both scheduled values are set. Used
    /// as the small subtitle under the topic on the call screen.
    var scheduledRangeLabel: String? {
        guard let start = scheduledStart, let end = scheduledEnd else { return nil }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return "\(f.string(from: start)) – \(f.string(from: end))"
    }

    /// Just the end-time portion, e.g. `"3:00 PM"`. Used by the Skype
    /// variant's status line to reassure the user the session will
    /// auto-end without them having to come back to press anything.
    var scheduledEndLabel: String? {
        guard let end = scheduledEnd else { return nil }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: end)
    }

    // MARK: - Start

    /// Kicks off the audio session. Preview path simulates the connect;
    /// runtime path checks mic permission, hits `/bookings/:id/join`, and
    /// joins the Agora channel with the returned config.
    func startCall() {
        glowPulse = true
        ringPulse = true

        // Preview / design path — no permission, no network, no Agora.
        guard let bookingId else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.4)) { self.callStatus = .active }
            }
            startTimer()
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                // 1. Fetch join context from the backend. The connection
                //    type on the response decides which branch we take
                //    from here — in-app voice via Agora vs. external
                //    Skype/Zoom link.
                let response = try await self.api.joinCall(id: bookingId).data
                self.connectionType = response.connectionType

                switch response.connectionType {
                case .inAppVoice:
                    try await self.startInAppVoice(config: response.agoraConfig)
                case .skypeZoom:
                    try await self.startExternalMeeting(config: response.externalConfig)
                }
            } catch {
                self.joinError = error.userMessage
            }
        }
    }

    /// Agora audio path — mic permission, engine init, channel join.
    private func startInAppVoice(config: JoinCallResponse.AgoraConfig?) async throws {
        // Mic permission is only needed for the in-app voice path. Use
        // the dedicated `micPermissionDenied` signal (not `joinError`)
        // so the shell can show a tailored alert with an Open Settings
        // deep-link instead of a generic Dismiss-only error.
        let granted = await AgoraManager.checkForPermissions()
        guard granted else {
            self.micPermissionDenied = true
            return
        }

        guard let config else {
            self.joinError = "This booking isn't set up for in-app voice."
            return
        }

        self.agora.initializeAgora(appId: AppEnvironment.current.agoraAppId)
        await self.agora.joinChannel(using: config)

        // Timer counts elapsed since scheduled start (or local join if
        // unknown). Runs whether we're connecting or already active so
        // both sides see the same "starts in / elapsed" value.
        self.joinStartTime = Date()
        self.startTimer()
    }

    /// External meeting (Skype/Zoom) path — no mic, no Agora, no auto-
    /// confirm. The connection is genuine only when the user actually
    /// opens the link; `openExternalLink()` handles that + fires
    /// `confirm-connection`. This method just stashes the URL and lets
    /// the view render the copy/open buttons.
    private func startExternalMeeting(config: JoinCallResponse.ExternalConfig?) async throws {
        guard let urlString = config?.joinUrl, let url = URL(string: urlString) else {
            self.joinError = "This booking is missing a meeting link. Contact the other party."
            return
        }
        self.externalJoinURL = url

        // No live-audio state to sync; leave `callStatus` at
        // `.connecting` so the elapsed timer still ticks (schedule-
        // anchored — useful even without a channel to join).
        self.joinStartTime = Date()
        self.startTimer()
    }

    // MARK: - External meeting actions

    /// Fired by the "Open in Skype/Zoom" button. Opens the external
    /// URL via `UIApplication.open`, flips the "hasOpened" flag so the
    /// status line updates, minimizes the call so the user can hand off
    /// to the external app cleanly, and fires `confirm-connection` with
    /// `method: "skype_zoom"` — same booking-lifecycle contract as the
    /// Agora path.
    func openExternalLink() {
        guard let url = externalJoinURL else { return }

        UIApplication.shared.open(url) { [weak self] _ in
            // `success` here just means iOS was able to hand off; we
            // fire regardless. iOS will surface an install prompt if
            // Skype isn't present, which is acceptable UX per the spec.
            guard let self else { return }
            self.hasOpenedExternalLink = true
            self.confirmConnectionOnce()
            CallCenter.shared.minimize()
        }
    }

    /// Copies the external URL to the pasteboard so the user can paste
    /// it into another app / device. Deliberately does NOT fire
    /// `confirm-connection` — copying isn't a genuine engagement
    /// signal, per the spec.
    func copyExternalLinkToPasteboard() {
        guard let url = externalJoinURL else { return }
        UIPasteboard.general.string = url.absoluteString
        withAnimation(.easeInOut(duration: 0.2)) {
            showLinkCopiedToast = true
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self?.showLinkCopiedToast = false
                }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        // Seed once so the view shows the correct value before the
        // first tick.
        recomputeElapsed()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.recomputeElapsed() }
        }
    }

    /// Compute `elapsedSeconds` from wall-clock time, anchored to
    /// `scheduledStart` when available so both participants see the
    /// same number regardless of who joined first. Falls back to the
    /// local join time only when the scheduled start isn't provided
    /// (preview / legacy call sites).
    private func recomputeElapsed() {
        let anchor = scheduledStart ?? joinStartTime ?? Date()
        elapsedSeconds = Int(Date().timeIntervalSince(anchor))
        enforceMaxOvertimeCutoff()
    }

    /// Abuse guard — force-close the call if it has been running more
    /// than the overtime cutoff past `scheduledEnd`. Belt-and-suspenders
    /// alongside the Agora RTC token's own expiry (which handles
    /// in_app_voice) and, for the Skype/Zoom variant, the only backstop
    /// we have since there's no server-controlled session on that path.
    /// Fires exactly once — the `isEndingCall` / `.ended` guards keep
    /// the per-second timer tick from re-invoking `endCall` while the
    /// teardown is in flight.
    ///
    /// TEMP: cutoff is 5 min for testing; revert to 3600 (1 hour) for
    /// production.
    private func enforceMaxOvertimeCutoff() {
        guard let scheduledEnd else { return }
        guard callStatus != .ended, !isEndingCall else { return }
        let overtimeCutoffSeconds: TimeInterval = 5 * 60 // TEMP: was 3600
        let cutoff = scheduledEnd.addingTimeInterval(overtimeCutoffSeconds)
        guard Date() >= cutoff else { return }
        CallCenter.shared.endCall()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /// Ensure the timer is running and elapsed is fresh — called from
    /// the view on appear so scheduled-start-based elapsed stays honest
    /// even during the pre-active phases. Idempotent.
    func ensureTimerRunning() {
        guard timer == nil else { return }
        startTimer()
    }

    // MARK: - Backend connection confirmation

    /// Fires `PATCH /bookings/:id/confirm-connection` exactly once per
    /// call, the moment both parties are actually on the Agora channel.
    /// This is the gate that flips the booking from `confirmed` to
    /// `in_progress`; without it, the subsequent `POST /end` refuses
    /// to complete the session and the row gets swept to `missed` by
    /// the server's expire-past-sessions cron.
    ///
    /// Idempotency is handled two ways:
    /// 1. `hasConfirmedConnection` local guard — no duplicate HTTP
    ///    calls even if the state briefly re-enters (.ready, .ready)
    ///    after a rejoin.
    /// 2. Server returns 409 `INVALID_STATUS` on a second attempt
    ///    (either from us or the peer) because the row is no longer
    ///    `confirmed`. We silently swallow that; it means someone
    ///    else already flipped it, which is the desired outcome.
    ///
    /// Any other failure is logged (in debug builds) but doesn't
    /// interrupt the call — the audio session keeps working, and the
    /// user can still hang up. The session may end up flagged
    /// `missed` server-side, but that's a smaller UX hit than blocking
    /// the call itself.
    private func confirmConnectionOnce() {
        guard !hasConfirmedConnection else { return }
        guard let bookingId else { return }
        // Fire even on rejoin. Per the Aug-16 backend change
        // (`docs/ios/CALL-END-SEMANTICS.md`), a hangup no longer marks
        // the booking `completed` — it stays `in_progress` for the
        // whole scheduled window, and `confirm-connection` is now
        // idempotent on an already-`in_progress` booking (200 instead
        // of the old 409 INVALID_STATUS). Previously we skipped the
        // call on rejoin to avoid the 409; that skip is now obsolete.
        // 409 handling below stays as a defensive backstop.
        hasConfirmedConnection = true

        let timestamp = ISO8601DateFormatter().string(from: Date())
        // Reflect which transport actually established the meeting so
        // the server records the right value. Defaults to in_app_voice
        // to preserve prior behavior when the type is somehow unset.
        let method = connectionType?.rawValue ?? ConnectionType.inAppVoice.rawValue

        Task { [weak self] in
            guard let self else { return }
            do {
                _ = try await self.api.confirmCallConnection(
                    id: bookingId,
                    connectionStatus: "connected",
                    timestamp: timestamp,
                    method: method
                )
            } catch {
                // 409 INVALID_STATUS = someone else already flipped
                // the booking; benign. Anything else is best-effort
                // — don't fail the call over a metadata blip.
                #if DEBUG
                print("[CallCenter] confirm-connection failed:", error)
                #endif
            }
        }
    }

    // MARK: - Audio controls

    func toggleMute() {
        if isMuted {
            agora.unmutedMic()
            isMuted = false
        } else {
            agora.mutedMic()
            isMuted = true
        }
    }

    func toggleSpeaker() {
        if isSpeakerOn {
            agora.useEar()
            isSpeakerOn = false
        } else {
            agora.useSpeaker()
            isSpeakerOn = true
        }
    }

    // MARK: - End

    /// Peer formally hung up (server pushed `call.ended`). We deliberately
    /// don't tear down the local side — the user stays on the screen with
    /// the "waiting" visual so they can either wait for a rejoin (if the
    /// peer just tapped Hang Up by accident and the server allows it) or
    /// leave on their own by pressing Hang Up. All the actual teardown
    /// (leave channel, POST /end, dismiss) lives in `handleEndCall` and
    /// only runs when the local user chooses.
    func handlePeerLeft() {
        guard callStatus != .ended else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            callStatus = .waitingForPeer
        }
    }

    /// Fires the end-call animation, tears down the Agora session, POSTs
    /// `/bookings/:id/end`, then dismisses.
    ///
    /// **End-reason selection** — the server transitions the booking
    /// only on `end_reason: "completed"`, and only if the booking is
    /// already `in_progress` (i.e. `confirm-connection` succeeded).
    /// So the rule is:
    ///
    /// - `hasConfirmedConnection == true` (both parties actually joined
    ///   at some point) → send `.completed`. Booking goes `in_progress
    ///   → completed`.
    /// - `hasConfirmedConnection == false` (user hung up before the
    ///   peer arrived, or before Agora finished connecting) → send
    ///   `.manualExit`. Server keeps status unchanged; the sweep cron
    ///   will mark it `missed` after the scheduled end, which is the
    ///   correct outcome for a bail-out.
    func handleEndCall(onDismiss: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isEndingCall = true
            callStatus = .ended
        }
        stopTimer()

        let endReason: EndReason = hasConfirmedConnection ? .completed : .manualExit

        Task { [weak self] in
            guard let self else { return }
            await self.agora.leaveChannel()

            // Always POST /end. Per the Aug-16 backend change
            // (`docs/ios/CALL-END-SEMANTICS.md`), a hangup no longer
            // completes the booking — it stays `in_progress` until
            // 15 min after `end_time`. `/end` on an `in_progress`
            // booking remains valid across rejoins and is what records
            // `actual_duration_secs` / `end_reason` for this leg. The
            // `isRejoin` skip that used to sit here was defensive
            // against a 409 that no longer fires.
            if let bookingId = self.bookingId {
                let duration = self.joinStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
                _ = try? await self.api.endCall(
                    id: bookingId,
                    actualDuration: max(0, duration),
                    endReason: endReason
                )
            }

            self.agora.destroyAgoraEngine()

            try? await Task.sleep(nanoseconds: 600_000_000)
            onDismiss()
        }
    }

    // MARK: - Error mapping

}
