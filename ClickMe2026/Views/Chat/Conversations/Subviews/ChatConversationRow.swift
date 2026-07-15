//
//  ChatConversationRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single conversation preview row

struct ChatConversationRow: View {
    let chat: ChatPreview
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                ChatConversationAvatar(imageURL: chat.imageURL, isOnline: chat.isOnline)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(chat.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(ChatConversationsBrand.onSurface)
                            .lineLimit(1)

                        Spacer()

                        HStack(spacing: 5) {
                            if chat.isOnline {
                                Circle()
                                    .fill(ChatConversationsBrand.brandGreen)
                                    .frame(width: 8, height: 8)
                                    .shadow(color: ChatConversationsBrand.brandGreen.opacity(0.70), radius: 4)
                            }
                            Text(chat.timeLabel)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundColor(chat.isOnline ? ChatConversationsBrand.onSurface : ChatConversationsBrand.onSurfaceVar)
                        }
                    }

                    Text(chat.lastMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(ChatConversationsBrand.onSurfaceVar)
                        .lineLimit(2)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ChatConversationsBrand.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(ChatConversationsBrand.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ChatRowStyle())
    }
}
