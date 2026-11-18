//
//  ChattingMessageBubble.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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

    /// My bubble whose POST has not answered yet (D-01).
    private var isPending: Bool {
        message.sender == .me && message.sendState == .sending
    }

    /// My bubble whose POST failed in a way a retry may fix (D-01).
    private var isFailed: Bool {
        message.sender == .me && message.sendState == .failed
    }

    /// Width of the failed glyph plus its gap to the bubble (UI-SPEC: 20 pt,
    /// 8 pt before the bubble).
    private static let failedGlyphSize: CGFloat = 20
    private static let failedGlyphGap: CGFloat = 8

    var body: some View {
        let isMe = message.sender == .me
        return HStack(alignment: .bottom, spacing: 8) {
            if isMe { Spacer(minLength: 56) }

            if !isMe {
                ChattingAvatar(url: message.avatarURL, size: 34)
            }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 2) {
                Text(isMe ? myName : message.senderName)
                    .font(.brand(.caption2, weight: .medium))
                    .foregroundColor(ChattingBrand.senderLabel)
                    .padding(.horizontal, 4)

                Text(message.body)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(isFailed ? Brand.onSurface : (isMe ? ChattingBrand.myText : ChattingBrand.onSurface))
                    .lineSpacing(3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        // The failed state dims the fill only, never the whole
                        // bubble, so the text keeps its contrast (UI-SPEC A1).
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(bubbleFill(isMe: isMe))
                    )
                    .overlay {
                        if isFailed {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Brand.error.opacity(0.5), lineWidth: 1)
                        }
                    }
                    // Laid out as an overlay offset left of the bubble rather than
                    // as an HStack sibling, so the 260 pt frame below sees the same
                    // content as in the Sending state and the text never re-wraps
                    // when the send fails. Centred on the bubble only, so the
                    // sender label and the status line keep their alignment.
                    .overlay(alignment: .leading) {
                        if isFailed {
                            Image(systemName: "exclamationmark.circle.fill")
                                .resizable()
                                .frame(width: Self.failedGlyphSize, height: Self.failedGlyphSize)
                                .foregroundColor(Brand.destructive)
                                .offset(x: -(Self.failedGlyphSize + Self.failedGlyphGap))
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(maxWidth: 260, alignment: isMe ? .trailing : .leading)

                HStack(spacing: 4) {
                    if isPending {
                        Text("Sending…")
                    } else if isFailed {
                        Text("Not sent. Tap to retry")
                            .font(.brand(.caption))
                            .foregroundColor(Brand.error)
                    } else {
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
                }
                .font(.brand(.caption2, weight: .regular))
                .foregroundColor(ChattingBrand.onSurfaceVar)
                .padding(.horizontal, 4)
                .animation(.easeInOut(duration: 0.2), value: message.status)
                .animation(.easeInOut(duration: 0.2), value: message.sendState)
            }
            // A pending bubble reads as one element: "{text}. Sending." (UI-SPEC L1).
            .accessibilityElement(children: isPending ? .ignore : .contain)
            .accessibilityLabel(isPending ? "\(message.body). Sending." : "")

            if isMe {
                ChattingAvatar(url: message.avatarURL, size: 34)
            }

            if !isMe { Spacer(minLength: 56) }
        }
    }

    private func bubbleFill(isMe: Bool) -> Color {
        if isFailed { return ChattingBrand.myBubble.opacity(0.4) }
        return isMe ? ChattingBrand.myBubble : ChattingBrand.theirBubble
    }
}
