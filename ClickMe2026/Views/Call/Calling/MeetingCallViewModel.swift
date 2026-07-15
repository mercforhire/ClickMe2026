//
//  MeetingCallViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class MeetingCallViewModel: ObservableObject {

    // MARK: Content
    @Published var expertName: String
    @Published var expertImageURL: String

    // MARK: Call state
    @Published var callStatus: CallStatus
    @Published var elapsedSeconds: Int
    @Published var isMuted: Bool
    @Published var isSpeakerOn: Bool
    @Published var isEndingCall: Bool

    // MARK: Avatar pulse animation
    @Published var ringPulse: Bool
    @Published var glowPulse: Bool

    private var timer: Timer?

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
        self.expertName = expertName
        self.expertImageURL = expertImageURL
        self.callStatus = callStatus
        self.elapsedSeconds = elapsedSeconds
        self.isMuted = isMuted
        self.isSpeakerOn = isSpeakerOn
        self.isEndingCall = isEndingCall
        self.ringPulse = ringPulse
        self.glowPulse = glowPulse
    }

    // MARK: Derived

    var timerString: String {
        let m = elapsedSeconds / 60
        let s = elapsedSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    // MARK: Actions

    /// Starts the pulse animations, ticks the elapsed timer, and simulates a
    /// 6-second connecting → active transition.
    func startCall() {
        glowPulse = true
        ringPulse = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: 0.4)) {
                self.callStatus = .active
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedSeconds += 1 }
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func toggleMute() { isMuted.toggle() }
    func toggleSpeaker() { isSpeakerOn.toggle() }

    /// Fires the end-call animation, stops the timer, and dispatches the
    /// caller's dismissal after a brief 0.6s delay.
    func handleEndCall(onDismiss: @escaping () -> Void) {
        withAnimation(.easeInOut(duration: 0.25)) {
            isEndingCall = true
            callStatus = .ended
        }
        stopTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            onDismiss()
        }
    }
}
