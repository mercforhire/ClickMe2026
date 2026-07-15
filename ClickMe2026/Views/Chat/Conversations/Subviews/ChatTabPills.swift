//
//  ChatTabPills.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Clients / Internal tab pills

struct ChatTabPills: View {
    @Binding var activeTab: ChatTab

    var body: some View {
        HStack(spacing: 10) {
            pill("Clients", tab: .clients)
            pill("Internal", tab: .internal_)
            Spacer()
        }
    }

    private func pill(_ label: String, tab: ChatTab) -> some View {
        let isActive = activeTab == tab

        return Button {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                activeTab = tab
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isActive ? ChatConversationsBrand.onSurface : ChatConversationsBrand.onSurfaceVar)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isActive ? ChatConversationsBrand.activePill : Color.clear)
                        .overlay(
                            Capsule()
                                .stroke(isActive ? ChatConversationsBrand.brandGreen.opacity(0.55) : ChatConversationsBrand.onSurfaceVar.opacity(0.25),
                                        lineWidth: 1)
                                .shadow(color: isActive ? ChatConversationsBrand.brandGreen.opacity(0.18) : .clear, radius: 4)
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
