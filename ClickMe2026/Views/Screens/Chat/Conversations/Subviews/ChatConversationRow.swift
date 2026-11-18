//
//  ChatConversationRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Single conversation preview row

struct ChatConversationRow: View {
    let chat: ChatPreview
    let action: () -> Void

    /// The pill's minimum size, scaled with Dynamic Type (CHAT-07, D-14).
    @ScaledMetric private var pillSize: CGFloat = 24

    private var isUnread: Bool { chat.unreadCount > 0 }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                ChatConversationAvatar(imageURL: chat.imageURL, isOnline: chat.isOnline)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(chat.name)
                            .font(.brand(.callout, weight: .bold))
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
                                .font(.brand(.caption, weight: .regular))
                                .foregroundColor(chat.isOnline ? ChatConversationsBrand.onSurface : ChatConversationsBrand.onSurfaceVar)
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(chat.lastMessage)
                            .font(.brand(.subheadline, weight: isUnread ? .bold : .regular))
                            .foregroundColor(
                                isUnread ? ChatConversationsBrand.onSurface : ChatConversationsBrand.onSurfaceVar
                            )
                            .lineLimit(2)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)

                        if let label = ChatUnreadRules.badgeLabel(count: chat.unreadCount) {
                            unreadPill(label)
                        }
                    }
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
        .animation(.easeInOut(duration: 0.2), value: chat.unreadCount)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            ChatUnreadRules.rowAccessibilityLabel(
                name: chat.name,
                count: chat.unreadCount,
                preview: chat.lastMessage,
                time: chat.timeLabel,
                isOnline: chat.isOnline
            )
        )
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Unread pill

    /// Brand capsule with the count. `.fixedSize()` so the pill never
    /// truncates; the preview beside it gives way instead.
    private func unreadPill(_ label: String) -> some View {
        Text(label)
            .font(.brand(.caption, weight: .bold))
            .foregroundColor(Brand.onPrimary)
            .padding(.horizontal, 8)
            .frame(minWidth: pillSize, minHeight: pillSize)
            .background(Capsule().fill(Brand.primary))
            .fixedSize()
            .transition(.opacity)
    }
}
