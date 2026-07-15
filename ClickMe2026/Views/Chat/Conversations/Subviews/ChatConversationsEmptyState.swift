//
//  ChatConversationsEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Empty search state

struct ChatConversationsEmptyState: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar.opacity(0.40))
            Text("No conversations found")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)
            Spacer()
        }
    }
}
