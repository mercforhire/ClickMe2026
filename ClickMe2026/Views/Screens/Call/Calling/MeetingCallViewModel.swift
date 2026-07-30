//
//  MeetingCallViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
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

    /// Non-fatal error surfaced from the join flow (permission denied,
    /// server error, wrong meeting type). `CallCenter` picks it up and
    /// forwards to the shell alert.
    @Published var joinError: String?

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
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.peerId = peerId
        self.expertName = expertName
        self.expertImageURL = expertImageURL
        self.topic = topic
        self.scheduledStart = scheduledStart
        self.scheduledEnd = scheduledEnd
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
                // 1. Mic permission.
                let granted = await AgoraManager.checkForPermissions()
                guard granted else {
                    self.joinError = "Microphone permission is required for the call. Grant it in Settings and try again."
                    return
                }

                // 2. Fetch Agora config from the backend.
                let response = try await self.api.joinCall(id: bookingId).data
                guard response.connectionType == .inAppVoice,
                      let config = response.agoraConfig
                else {
                    self.joinError = "This booking isn't set up for in-app voice."
                    return
                }

                // 3. Init engine + join channel.
                self.agora.initializeAgora(appId: AppEnvironment.current.agoraAppId)
                await self.agora.joinChannel(using: config)

                // 4. Start the elapsed timer.
                self.joinStartTime = Date()
                self.startTimer()
            } catch {
                self.joinError = error.userMessage
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
    func handleEndCall(onDismiss: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isEndingCall = true
            callStatus = .ended
        }
        stopTimer()

        Task { [weak self] in
            guard let self else { return }
            await self.agora.leaveChannel()

            if let bookingId = self.bookingId {
                let duration = self.joinStartTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
                _ = try? await self.api.endCall(
                    id: bookingId,
                    actualDuration: max(0, duration),
                    endReason: .manualExit
                )
            }

            self.agora.destroyAgoraEngine()

            try? await Task.sleep(nanoseconds: 600_000_000)
            onDismiss()
        }
    }

    // MARK: - Error mapping

}
