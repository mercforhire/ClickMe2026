//
//  ChatConversationAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Avatar with online indicator

struct ChatConversationAvatar: View {
    let imageURL: String
    let isOnline: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AsyncImage(url: URL(string: imageURL)) { phase in
                switch phase {
                case let .success(img):
                    img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.14, green: 0.20, blue: 0.16)
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(Circle())
            .overlay(Circle().stroke(ChatConversationsBrand.cardBorder, lineWidth: 1))

            if isOnline {
                Circle()
                    .fill(ChatConversationsBrand.brandGreen)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(ChatConversationsBrand.bg, lineWidth: 2))
                    .shadow(color: ChatConversationsBrand.brandGreen.opacity(0.70), radius: 4)
            }
        }
    }
}
