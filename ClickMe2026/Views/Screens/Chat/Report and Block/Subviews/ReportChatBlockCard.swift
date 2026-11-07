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
// Three visual states — looser than `docs/ios/CHAT-UNBLOCK.md` §5
// because legacy pre-2026-10-17 blocks (§7) have no recorded blocker
// and would otherwise leave the user stranded. We ALWAYS surface an
// Unblock button on a blocked thread and let the server adjudicate —
// 200 unblocks, 403 NOT_BLOCKER reconciles state so the button goes
// away on the next render.
//
// | isBlocked | blockedByMe | Rendered state |
// |-----------|-------------|----------------|
// | false     | n/a         | "Block User" primary CTA |
// | true      | true        | "You blocked this" + Unblock button |
// | true      | false       | "Blocked by the other party" + Unblock button (legacy-safe) |

struct ReportChatBlockCard: View {
    let isBlocked: Bool
    let blockedByMe: Bool
    let isWorking: Bool
    /// True after a `403 NOT_BLOCKER` denial — hide the Unblock button
    /// so the user can't thrash on it.
    var unblockDenied: Bool = false
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
                    Button(action: isBlocked ? onUnblockTap : onBlockTap) {
                        Text(buttonText)
                            .font(.brand(.subheadline, weight: .bold))
                            .foregroundColor(ReportChatBrand.errorRed)
                            .padding(.horizontal, 20)
                            .frame(height: 42)
                            .overlay(
                                Capsule().stroke(ReportChatBrand.errorBorder, lineWidth: 1.5)
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

    /// Hide the button only after the server has definitively denied an
    /// unblock. Otherwise always show it so legacy blocks (§7) can be
    /// lifted via server adjudication.
    private var shouldShowButton: Bool {
        !(isBlocked && unblockDenied)
    }

    // MARK: - Derived copy

    private var headlineText: String {
        if isBlocked && unblockDenied { return "This conversation was blocked by the other person" }
        if isBlocked && blockedByMe   { return "You blocked this conversation" }
        if isBlocked                  { return "This conversation is blocked" }
        return "Block User"
    }

    private var bodyText: String {
        if isBlocked && unblockDenied {
            return "You can still see earlier messages, but neither of you can send new ones. Only the person who blocked this conversation can lift it."
        }
        if isBlocked && blockedByMe {
            return "Unblocking will let this user see your profile, send you messages, and book appointments with you again."
        }
        if isBlocked {
            return "You can still see earlier messages, but neither of you can send new ones. If you blocked this conversation, you can lift the block below."
        }
        return "Blocking this user will prevent them from seeing your profile, sending you messages, or booking appointments with you. They will not be notified that you have blocked them."
    }

    private var buttonText: String {
        isBlocked ? "Unblock User" : "Block User"
    }
}
