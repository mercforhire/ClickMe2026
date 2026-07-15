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
            }

            if isMe {
                ChattingAvatar(url: message.avatarURL, size: 34)
            }

            if !isMe { Spacer(minLength: 56) }
        }
    }
}
