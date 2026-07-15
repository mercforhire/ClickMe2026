//
//  AllCategoriesQuickChips.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Horizontal quick-filter chips

struct AllCategoriesQuickChips: View {
    let categories: [Category]
    let isSelected: (Category) -> Bool
    let onToggle: (Category) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories) { category in
                    chip(category)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ category: Category) -> some View {
        let selected = isSelected(category)
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                onToggle(category)
            }
        } label: {
            Text(category.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(selected ? AllCategoriesBrand.onPrimary : AllCategoriesBrand.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selected ? AllCategoriesBrand.brandGreen : Color.white.opacity(0.07))
                        .overlay(
                            Capsule()
                                .stroke(selected ? AllCategoriesBrand.brandGreen : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: selected ? AllCategoriesBrand.brandGreen.opacity(0.40) : .clear, radius: 6)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: selected)
    }
}
