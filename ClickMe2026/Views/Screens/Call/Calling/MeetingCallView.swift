//
//  MeetingCallView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Call State

enum CallStatus {
    /// Local side hasn't finished joining the Agora channel yet — token
    /// fetch, engine init, or `joinChannel` still in flight.
    case connecting
    /// Local side is in the channel, but the peer hasn't arrived. Shows
    /// "Waiting for other person…" so the user knows they're connected
    /// and the app is now waiting on the peer.
    case waitingForPeer
    /// Both parties in the channel — the timer runs.
    case active
    case ended

    var label: String {
        switch self {
        case .connecting:     return "Connecting..."
        case .waitingForPeer: return "Waiting for other person..."
        case .active:         return "Connected"
        case .ended:          return "Call Ended"
        }
    }
}

// MARK: - Active Call View

/// The expanded, full-screen call surface. As of the CallCenter migration
/// this view no longer *owns* its `MeetingCallViewModel` — the VM lives
/// on `CallCenter.shared` for the entire lifetime of a call so the call
/// can survive minimize/expand and screen navigations. The VM is passed
/// in via `@ObservedObject`; `startCall` / `stopTimer` are handled by
/// `CallCenter`, not by this view.
struct MeetingCallView: View {
    @ObservedObject var viewModel: MeetingCallViewModel

    /// Called when the user taps Minimize. Defaults to
    /// `CallCenter.shared.minimize()` at the call site.
    var onMinimize: () -> Void

    var body: some View {
        ZStack {
            MeetingCallBackground()

            VStack(spacing: 0) {
                MeetingCallTopBar(onMinimizeTap: onMinimize)
                    .padding(.top, 20)
                    .padding(.horizontal, 24)

                if viewModel.isInFinalStretch || viewModel.isPastScheduledEnd {
                    endingSoonBanner
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer()

                MeetingCallAvatar(
                    expertImageURL: viewModel.expertImageURL,
                    myAvatarURL: viewModel.myAvatarURL,
                    callStatus: viewModel.callStatus,
                    glowPulse: viewModel.glowPulse,
                    ringPulse: viewModel.ringPulse
                )
                .padding(.bottom, 40)

                MeetingCallInfo(
                    expertName: viewModel.expertName,
                    topic: viewModel.topic,
                    scheduledRangeLabel: viewModel.scheduledRangeLabel,
                    timerString: viewModel.timerString,
                    statusLabel: viewModel.callStatus.label,
                    remainingLabel: viewModel.remainingLabel,
                    isNearOrPastEnd: viewModel.isInFinalStretch || viewModel.isPastScheduledEnd
                )
                .padding(.bottom, 56)

                MeetingCallControls(
                    isMuted: viewModel.isMuted,
                    isSpeakerOn: viewModel.isSpeakerOn,
                    onOpenChat: { CallCenter.shared.requestOpenChatWithPeer() },
                    onToggleMute: { viewModel.toggleMute() },
                    onToggleSpeaker: { viewModel.toggleSpeaker() }
                )
                .padding(.bottom, 52)

                MeetingCallEndButton(
                    isEnding: viewModel.isEndingCall,
                    action: { CallCenter.shared.endCall() }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.isInFinalStretch)
        .animation(.easeInOut(duration: 0.25), value: viewModel.isPastScheduledEnd)
        // Server pushed `call.ended` for this booking — the peer hung
        // up. Drop back to the "waiting for peer" visual so the local
        // user can wait for a rejoin or hang up manually. Only the
        // local Hang Up button runs the teardown.
        .onChange(of: viewModel.peerEndedCall) { _, ended in
            if ended {
                viewModel.handlePeerLeft()
            }
        }
    }

    // MARK: - Session-ending banner

    /// Amber banner shown across the top of the call in two states:
    ///
    /// - Within the last 5 minutes → "Session ending soon" with the
    ///   remaining count in a small chip.
    /// - Past the scheduled end   → "Scheduled time complete — you
    ///   can wrap up when ready." (Soft ending — call keeps going.)
    private var endingSoonBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "hourglass")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.orange)
            Text(bannerText)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.orange.opacity(0.14))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.orange.opacity(0.50), lineWidth: 1))
        )
    }

    private var bannerText: String {
        if viewModel.isPastScheduledEnd {
            return "Scheduled time complete — you can wrap up when ready."
        }
        return "Session ending soon — please start wrapping up."
    }
}

// MARK: - Preview harness

#Preview("Expanded") {
    MeetingCallView(
        viewModel: MeetingCallViewModel(),
        onMinimize: {}
    )
    .preferredColorScheme(.dark)
}
