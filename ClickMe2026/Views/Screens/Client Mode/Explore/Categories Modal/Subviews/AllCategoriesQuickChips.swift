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
    let isAllSelected: Bool
    let onSelectAll: () -> Void
    let isSelected: (Category) -> Bool
    let onToggle: (Category) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                allChip

                ForEach(categories) { category in
                    chip(category.name, selected: isSelected(category)) {
                        onToggle(category)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: Chips

    private var allChip: some View {
        chip("All", selected: isAllSelected) {
            onSelectAll()
        }
    }

    private func chip(_ label: String, selected: Bool, tap: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                tap()
            }
        } label: {
            Text(label)
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
