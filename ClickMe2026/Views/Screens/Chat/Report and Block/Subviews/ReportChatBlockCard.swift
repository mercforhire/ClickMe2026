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
// Three visual states, per `docs/ios/CHAT-UNBLOCK.md` §5:
//
// | isBlocked | blockedByMe | Rendered state |
// |-----------|-------------|----------------|
// | false     | n/a         | "Block User" primary CTA |
// | true      | true        | "Unblock User" primary CTA |
// | true      | false       | neutral banner — "You can't reply to this conversation", no action |

struct ReportChatBlockCard: View {
    let isBlocked: Bool
    let blockedByMe: Bool
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

    // MARK: - Derived copy

    private var shouldShowButton: Bool {
        // Blocked by the OTHER party — no action available, just the
        // explainer banner. Any other state (unblocked, or blocked-by-me)
        // offers a button.
        !(isBlocked && !blockedByMe)
    }

    private var headlineText: String {
        if isBlocked && blockedByMe { return "You blocked this conversation" }
        if isBlocked               { return "You can't reply to this conversation" }
        return "Block User"
    }

    private var bodyText: String {
        if isBlocked && blockedByMe {
            return "Unblocking will let this user see your profile, send you messages, and book appointments with you again."
        }
        if isBlocked {
            return "The other person has blocked this conversation. You can still see earlier messages, but neither of you can send new ones."
        }
        return "Blocking this user will prevent them from seeing your profile, sending you messages, or booking appointments with you. They will not be notified that you have blocked them."
    }

    private var buttonText: String {
        isBlocked && blockedByMe ? "Unblock User" : "Block User"
    }
}
