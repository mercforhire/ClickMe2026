//
//  ReportChatBlockCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Block / Unblock card
//
// Three rows, per `docs/ios/CHAT-UNBLOCK.md` §5. Unblock is offered only to the
// person who blocked; a legacy block (§7, no recorded blocker) reads as blocked
// by the other person, and so does the state after a `403 NOT_BLOCKER` (§6).
// Copy describes only what blocking does here: it stops new messages in this
// conversation (D-05).
//
// | isBlocked | blockedByMe | Rendered state                                     |
// |-----------|-------------|----------------------------------------------------|
// | false     | n/a         | "Block User" card with a red Block User button      |
// | true      | true        | "You blocked this conversation" + Unblock User      |
// | true      | false       | "You can't reply to this conversation", no button   |

struct ReportChatBlockCard: View {
    let state: ChatBlockState
    /// The other person's name, used in the blocked-by-me body.
    let peerName: String
    let isWorking: Bool
    let onBlockTap: () -> Void
    let onUnblockTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text(headlineText)
                    .font(.brand(.title2, weight: .bold))
                    .foregroundColor(ReportChatBrand.onSurface)

                Text(bodyText)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(ReportChatBrand.onSurfaceVar)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if shouldShowButton {
                HStack {
                    Spacer()
                    Button(action: state.isBlocked ? onUnblockTap : onBlockTap) {
                        Text(buttonText)
                            .font(.brand(.subheadline, weight: .bold))
                            .foregroundColor(buttonTint)
                            .padding(.horizontal, 20)
                            .frame(height: 42)
                            .overlay(
                                Capsule().stroke(buttonStroke, lineWidth: 1.5)
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                    .disabled(isWorking)
                }
            }
        }
        .padding(20)
        .background(ReportChatGlassCard())
    }

    /// Block when nothing is blocked, Unblock for the blocker, nothing for the other side.
    private var shouldShowButton: Bool {
        !state.isBlocked || state.showsUnblock
    }

    // MARK: - Derived copy

    private var headlineText: String {
        guard state.isBlocked else { return "Block User" }
        return state.showsUnblock ? "You blocked this conversation" : "You can't reply to this conversation"
    }

    private var bodyText: String {
        guard state.isBlocked else {
            return "Blocking stops both of you from sending new messages in this conversation. "
                + "You can still see earlier messages. They won't be notified."
        }
        if state.showsUnblock {
            let trimmed = peerName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "this user" : trimmed
            return "Unblocking lets you and \(name) send messages in this conversation again."
        }
        return "You can still see earlier messages, but neither of you can send new ones. "
            + "Only the person who blocked this conversation can lift it."
    }

    private var buttonText: String {
        state.isBlocked ? "Unblock User" : "Block User"
    }

    /// Unblock uses the accent style (UI-SPEC A7); Block stays red.
    private var buttonTint: Color {
        state.isBlocked ? ReportChatBrand.brandGreen : ReportChatBrand.errorRed
    }

    private var buttonStroke: Color {
        state.isBlocked ? ReportChatBrand.brandGreen : ReportChatBrand.errorBorder
    }
}
