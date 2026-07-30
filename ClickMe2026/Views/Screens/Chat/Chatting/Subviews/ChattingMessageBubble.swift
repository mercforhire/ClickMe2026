//
//  ChattingMessageBubble.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single message bubble row (with avatar)

struct ChattingMessageBubble: View {
    let message: ChatMessage
    let myName: String

    /// Locale-aware short time formatter (e.g. "10:23 AM" in en-US,
    /// "10:23" in 24-hour locales). Cached statically so we don't
    /// allocate a new formatter for every bubble in the list.
    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        let isMe = message.sender == .me
        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 56) }

            if !isMe {
                ChattingAvatar(url: message.avatarURL, size: 34)
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(isMe ? myName : message.senderName)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(ChattingBrand.senderLabel)
                    .padding(.horizontal, 4)

                Text(message.body)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(isMe ? ChattingBrand.myText : ChattingBrand.onSurface)
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isMe ? ChattingBrand.myBubble : ChattingBrand.theirBubble)
                    )
                    .frame(maxWidth: 260, alignment: isMe ? .trailing : .leading)

                HStack(spacing: 4) {
                    Text(Self.timestampFormatter.string(from: message.timestamp))
                    // Only surface "Read" on my own bubbles — read state
                    // for peer messages isn't user-visible, and the
                    // socket receipt only flips this on the sender's
                    // side anyway.
                    if isMe, message.status == .read {
                        Text("· Read")
                            .foregroundColor(ChattingBrand.brandGreen)
                            .transition(.opacity)
                    }
                }
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundColor(ChattingBrand.onSurfaceVar)
                .padding(.horizontal, 4)
                .animation(.easeInOut(duration: 0.2), value: message.status)
            }

            if isMe {
                ChattingAvatar(url: message.avatarURL, size: 34)
            }

            if !isMe { Spacer(minLength: 56) }
        }
    }
}
