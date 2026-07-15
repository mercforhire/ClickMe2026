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
    let categories: [AllCategoriesView.CategoryItem]
    let onToggle: (Int) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories.indices, id: \.self) { i in
                    chip(categories[i], index: i)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ cat: AllCategoriesView.CategoryItem, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                onToggle(index)
            }
        } label: {
            Text(cat.name)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(cat.isSelected ? AllCategoriesBrand.onPrimary : AllCategoriesBrand.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(cat.isSelected ? AllCategoriesBrand.brandGreen : Color.white.opacity(0.07))
                        .overlay(
                            Capsule()
                                .stroke(cat.isSelected ? AllCategoriesBrand.brandGreen : Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: cat.isSelected ? AllCategoriesBrand.brandGreen.opacity(0.40) : .clear, radius: 6)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: cat.isSelected)
    }
}
