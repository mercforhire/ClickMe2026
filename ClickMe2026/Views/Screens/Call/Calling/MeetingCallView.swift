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

    /// Runtime init — POSTs `/bookings/:id/join`, initializes Agora,
    /// joins the returned channel, and posts `/bookings/:id/end` when
    /// the user hangs up.
    init(
        bookingId: UUID,
        expertName: String,
        expertImageURL: String,
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: MeetingCallViewModel(
            bookingId: bookingId,
            expertName: expertName,
            expertImageURL: expertImageURL
        ))
        self.onDismiss = onDismiss
    }

    /// Preview / test seam.
    init(
        viewModel: MeetingCallViewModel = MeetingCallViewModel(),
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onDismiss = onDismiss
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
        .alert(
            "Couldn't join call",
            isPresented: Binding(
                get: { viewModel.joinError != nil },
                set: { if !$0 { viewModel.joinError = nil } }
            ),
            presenting: viewModel.joinError
        ) { _ in
            Button("OK", role: .cancel) { onDismiss() }
        } message: { message in
            Text(message)
        }
    }
}

// MARK: - Preview harness

/// Presents the meeting call as a full-screen modal on top of a dummy
/// "Booking details" parent, so tapping X actually dismisses the call
/// back to the parent in the canvas.
private struct MeetingCallPreviewHarness: View {
    @State private var isPresented = true

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Booking details")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Session with Sophia Carter")
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Button {
                    isPresented = true
                } label: {
                    Text("Start call")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(MeetingCallBrand.onSurface)
                        .padding(.horizontal, 24)
                        .frame(height: 48)
                        .background(
                            Capsule().stroke(MeetingCallBrand.brandGreen, lineWidth: 1.5)
                        )
                }
            }
        }
        .fullScreenCover(isPresented: $isPresented) {
            MeetingCallView(onDismiss: { isPresented = false })
        }
    }
}

// MARK: - Previews

#Preview("Connecting") {
    MeetingCallPreviewHarness()
        .preferredColorScheme(.dark)
}
