//
//  ChatConversationsEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
                .font(.brand(.callout, weight: .medium))
                .foregroundColor(ChatConversationsBrand.onSurfaceVar)
            Spacer()
        }
    }
}
