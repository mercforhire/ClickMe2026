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
    case connecting, active, ended

    var label: String {
        switch self {
        case .connecting: return "Connecting..."
        case .active: return "Connected"
        case .ended: return "Call Ended"
        }
    }
}

// MARK: - Active Call View

struct MeetingCallView: View {
    @StateObject private var viewModel: MeetingCallViewModel

    var onDismiss: () -> Void

    // MARK: Init

    init(
        viewModel: MeetingCallViewModel = MeetingCallViewModel(),
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        expertName: String = "Sophia Carter",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/44.jpg",
        onDismiss: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: MeetingCallViewModel(
                expertName: expertName,
                expertImageURL: expertImageURL
            ),
            onDismiss: onDismiss
        )
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            MeetingCallBackground()

            VStack(spacing: 0) {
                MeetingCallTopBar(
                    onDismissTap: { viewModel.handleEndCall(onDismiss: onDismiss) }
                )
                .padding(.top, 20)
                .padding(.horizontal, 24)

                Spacer()

                MeetingCallAvatar(
                    expertImageURL: viewModel.expertImageURL,
                    callStatus: viewModel.callStatus,
                    glowPulse: viewModel.glowPulse,
                    ringPulse: viewModel.ringPulse
                )
                .padding(.bottom, 40)

                MeetingCallInfo(
                    expertName: viewModel.expertName,
                    timerString: viewModel.timerString,
                    statusLabel: viewModel.callStatus.label
                )
                .padding(.bottom, 56)

                MeetingCallControls(
                    isMuted: viewModel.isMuted,
                    isSpeakerOn: viewModel.isSpeakerOn,
                    onToggleMute: { viewModel.toggleMute() },
                    onToggleSpeaker: { viewModel.toggleSpeaker() }
                )
                .padding(.bottom, 52)

                MeetingCallEndButton(
                    isEnding: viewModel.isEndingCall,
                    action: { viewModel.handleEndCall(onDismiss: onDismiss) }
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear { viewModel.startCall() }
        .onDisappear { viewModel.stopTimer() }
    }
}

// MARK: - Previews

#Preview("Connecting") {
    MeetingCallView()
        .preferredColorScheme(.dark)
}

#Preview("Active Call") {
    ZStack {
        MeetingCallBrand.bg.ignoresSafeArea()
        MeetingCallView(
            expertName: "Sophia Carter",
            expertImageURL: "https://randomuser.me/api/portraits/women/44.jpg"
        )
    }
    .preferredColorScheme(.dark)
}
