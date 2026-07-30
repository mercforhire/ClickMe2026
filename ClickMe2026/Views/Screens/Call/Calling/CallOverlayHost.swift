//
//  CallOverlayHost.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Wraps a shell's content (client or expert home) with the two call
/// surfaces:
///
/// - Expanded call — presented via `.fullScreenCover`, which gives us
///   the same safe-area handling the original single-screen call used.
///   Trying to fake this with a sibling ZStack layer swallowed the
///   top-bar safe-area padding and left the minimize chevron pinned to
///   the very top of the screen.
/// - Minimized pill — a bottom-trailing overlay that only shows while
///   `isMinimized` is true. Tap re-expands the call by flipping
///   `isMinimized` back to `false`, which re-triggers the cover.
///
/// Also plumbs the "open chat with peer" signal from `CallCenter` back
/// into the shell's own tab-switch + push closure so the Chat button
/// on the call screen can jump to the Chats tab, and hosts the shared
/// "End the call to X" restriction alert.
struct CallOverlayHost: ViewModifier {
    @ObservedObject private var callCenter = CallCenter.shared

    /// Same signature as `OpenChatThreadAction.action` — the shell knows
    /// how to switch to Chats + push the thread.
    let onOpenChat: (UUID, String, String) -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: expandedBinding) {
                if let vm = callCenter.viewModel {
                    MeetingCallView(
                        viewModel: vm,
                        onMinimize: { callCenter.minimize() }
                    )
                }
            }
            // Minimized pill — bottom-right, above the tab bar.
            .overlay(alignment: .bottomTrailing) {
                if let vm = callCenter.viewModel, callCenter.isMinimized {
                    MeetingCallPill(viewModel: vm, onTap: { callCenter.expand() })
                        .padding(.trailing, 16)
                        .padding(.bottom, 96)
                        .transition(.scale(scale: 0.6).combined(with: .opacity))
                }
            }
            // Chat shortcut: when `requestOpenChatWithPeer()` resolves
            // the thread, it drops the payload here. We forward it to
            // the shell's own tab-switch + path-push closure, then
            // acknowledge so the signal doesn't re-fire.
            .onChange(of: callCenter.pendingChatOpen) { _, newValue in
                guard let payload = newValue else { return }
                onOpenChat(payload.threadId, payload.peerName, payload.peerAvatarURL)
                callCenter.acknowledgeChatOpen()
            }
            // Centralized "End the call to X" alert. Any restricted
            // action across the app can `attempt("do X")` on
            // CallCenter and this modifier renders the resulting
            // message — one alert covers every restricted surface.
            .alert(
                "Can't do that during a call",
                isPresented: Binding(
                    get: { callCenter.restrictionAlertMessage != nil },
                    set: { if !$0 { callCenter.restrictionAlertMessage = nil } }
                ),
                presenting: callCenter.restrictionAlertMessage
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
    }

    /// Cover is presented while a call is active AND not minimized.
    /// The `set` side responds to SwiftUI-driven dismissals (edge cases
    /// like swipe-down or programmatic teardown) by minimizing rather
    /// than ending the call — Hang Up is the only path that ends.
    private var expandedBinding: Binding<Bool> {
        Binding(
            get: { callCenter.viewModel != nil && !callCenter.isMinimized },
            set: { newValue in
                guard !newValue else { return }
                guard callCenter.viewModel != nil else { return }
                callCenter.minimize()
            }
        )
    }
}
