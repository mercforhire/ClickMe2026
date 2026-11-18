//
//  ChattingBlockedBanner.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Blocked / unavailable banner

/// Takes the composer's place when the thread is blocked or the other person is
/// unavailable (CHAT-03, D-03, D-07). The title says who blocked; copy and symbols
/// come from `ChatBlockState`. Only the blocker gets the Unblock capsule (D-08). At
/// a long name or a large text size the capsule moves under the title.
struct ChattingBlockedBanner: View {
    let mode: ChatBlockState.ComposerMode
    let peerName: String
    let isUnblocking: Bool
    let onUnblock: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 16) {
                titleRow
                Spacer(minLength: 0)
                unblockButton
            }
            VStack(alignment: .leading, spacing: 8) {
                titleRow
                unblockButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(
            ChattingBrand.navBg
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }

    private var titleRow: some View {
        HStack(spacing: 8) {
            if let symbol = ChatBlockState.bannerSymbol(for: mode) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                    .foregroundColor(ChattingBrand.onSurfaceVar)
                    .accessibilityHidden(true)
            }
            if let title = ChatBlockState.bannerTitle(for: mode) {
                Text(title)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(ChattingBrand.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// A restorative accent capsule, not red (UI-SPEC A7). Shown for `.blockedByMe` only.
    @ViewBuilder
    private var unblockButton: some View {
        if mode == .blockedByMe {
            Button(action: onUnblock) {
                Group {
                    if isUnblocking {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Brand.primary)
                            .accessibilityLabel("Unblocking")
                    } else {
                        Text("Unblock")
                            .font(.brand(.subheadline, weight: .bold))
                            .foregroundColor(Brand.primary)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 44)
                .overlay(Capsule().stroke(Brand.primary, lineWidth: 1.5))
                .contentShape(Capsule())
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(isUnblocking)
            .fixedSize()
            .accessibilityHint("You and \(hintName) can message each other again")
        }
    }

    private var hintName: String {
        let trimmed = peerName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "this user" : trimmed
    }
}

#Preview("Blocked by me") {
    ChattingBlockedBanner(mode: .blockedByMe, peerName: "Dr. Olivia Bennett", isUnblocking: false, onUnblock: {})
        .preferredColorScheme(.dark)
}

#Preview("Blocked by peer") {
    ChattingBlockedBanner(mode: .blockedByPeer, peerName: "Dr. Olivia Bennett", isUnblocking: false, onUnblock: {})
        .preferredColorScheme(.dark)
}

#Preview("Unblocking, large text") {
    ChattingBlockedBanner(mode: .blockedByMe, peerName: "Dr. Olivia Bennett", isUnblocking: true, onUnblock: {})
        .dynamicTypeSize(.accessibility3)
        .preferredColorScheme(.dark)
}

#Preview("Unavailable") {
    ChattingBlockedBanner(mode: .unavailable, peerName: "Dr. Olivia Bennett", isUnblocking: false, onUnblock: {})
        .preferredColorScheme(.dark)
}
