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

    // MARK: Content
    @Published var expertName: String
    @Published var expertImageURL: String

    // MARK: Call state
    @Published var callStatus: CallStatus
    @Published var elapsedSeconds: Int
    @Published var isMuted: Bool
    @Published var isSpeakerOn: Bool
    @Published var isEndingCall: Bool

    /// Non-fatal error surfaced from the join flow (permission denied,
    /// server error, wrong meeting type).
    @Published var joinError: String?

    // MARK: Avatar pulse animation
    @Published var ringPulse: Bool
    @Published var glowPulse: Bool

    // MARK: Dependencies

    let agora: AgoraManager
    private let api: ClickMeAPI

    // MARK: Internals

    private var timer: Timer?
    private var joinStartTime: Date?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Runtime init

    /// Runtime init — POSTs `/bookings/:id/join`, initializes the Agora
    /// engine, and joins the returned channel. Mic/speaker toggles route
    /// to `AgoraManager`. Ending the call leaves the channel and POSTs
    /// `/bookings/:id/end`.
    init(
        bookingId: UUID,
        expertName: String,
        expertImageURL: String,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.expertName = expertName
        self.expertImageURL = expertImageURL
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
    }

    // MARK: - Preview / design init

    init(
        expertName: String = "Sophia Carter",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        callStatus: CallStatus = .connecting,
        elapsedSeconds: Int = 0,
        isMuted: Bool = false,
        isSpeakerOn: Bool = false,
        isEndingCall: Bool = false,
        ringPulse: Bool = false,
        glowPulse: Bool = false
    ) {
        self.bookingId = nil
        self.expertName = expertName
        self.expertImageURL = expertImageURL
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

    /// Republish `AgoraManager`'s remote-connection state as our own
    /// `callStatus`. Without this the nested ObservableObject wouldn't
    /// trigger view updates through the parent VM.
    private func wireAgoraStateSync() {
        agora.$remoteConnectionState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .waiting:
                    // Only reflect "connecting" if we haven't already ended.
                    if self.callStatus != .ended { self.callStatus = .connecting }
                case .ready:
                    if self.callStatus != .ended {
                        withAnimation(.easeInOut(duration: 0.35)) { self.callStatus = .active }
                    }
                case .disconnected:
                    self.callStatus = .ended
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Derived

    var timerString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
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
                self.joinError = Self.errorMessage(for: error)
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedSeconds += 1 }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
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

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
