//
//  HomeExpertTabItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single tab — thin-line icon, neon green active state, glow dot below

struct HomeExpertTabItem: View {
    let tab: HomeExpertTab
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(isActive ? Brand.primary : Brand.onSurfaceVariant)
                    .shadow(
                        color: isActive ? Brand.primary.opacity(0.55) : .clear,
                        radius: isActive ? 10 : 0
                    )

                // label-md: 12 / 500
                Text(tab.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isActive ? Brand.primary : Brand.onSurfaceVariant)

                // Glow dot — visible only when active
                Circle()
                    .fill(Brand.primary)
                    .frame(width: 4, height: 4)
                    .shadow(color: Brand.primary.opacity(0.7), radius: 4)
                    .opacity(isActive ? 1 : 0)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
