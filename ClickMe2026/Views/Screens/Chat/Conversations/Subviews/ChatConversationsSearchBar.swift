//
//  ChatConversationsSearchBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Search field with clear button

struct ChatConversationsSearchBar: View {
    @Binding var text: String
    var onClear: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)

            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text("Search")
                        .foregroundColor(ChatConversationsBrand.onSurfaceVar)
                        .font(.system(size: 16, design: .rounded))
                }
                .foregroundColor(ChatConversationsBrand.onSurface)
                .font(.system(size: 16, design: .rounded))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .tint(ChatConversationsBrand.brandGreen)

            if !text.isEmpty {
                Button(action: onClear) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ChatConversationsBrand.onSurfaceVar.opacity(0.60))
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ChatConversationsBrand.fieldBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ChatConversationsBrand.brandGreen.opacity(0.40), lineWidth: 1.2)
                        .shadow(color: ChatConversationsBrand.brandGreen.opacity(0.12), radius: 4)
                )
        )
    }
}
