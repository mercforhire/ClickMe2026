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
/// come from `ChatBlockState`.
struct ChattingBlockedBanner: View {
    let mode: ChatBlockState.ComposerMode

    var body: some View {
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
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(minHeight: 56)
        .background(
            ChattingBrand.navBg
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
        )
        .accessibilityElement(children: .contain)
    }
}

#Preview("Blocked by me") {
    ChattingBlockedBanner(mode: .blockedByMe)
        .preferredColorScheme(.dark)
}

#Preview("Blocked by peer") {
    ChattingBlockedBanner(mode: .blockedByPeer)
        .preferredColorScheme(.dark)
}

#Preview("Unavailable") {
    ChattingBlockedBanner(mode: .unavailable)
        .preferredColorScheme(.dark)
}
