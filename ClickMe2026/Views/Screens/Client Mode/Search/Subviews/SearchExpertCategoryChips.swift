//
//  SearchExpertCategoryChips.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Horizontal category chips

struct SearchExpertCategoryChips: View {
    let categories: [Category]

    /// Slug of the selected category. Empty string means "All" is active —
    /// no filter applied.
    @Binding var selectedCategorySlug: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip("All", value: "")

                ForEach(categories) { category in
                    chip(category.name, value: category.id)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ label: String, value: String) -> some View {
        let isSelected = selectedCategorySlug == value
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedCategorySlug = value
            }
        } label: {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(isSelected ? SearchExpertBrand.onPrimary : SearchExpertBrand.onSurface)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? SearchExpertBrand.brandGreen : SearchExpertBrand.chipBg)
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? SearchExpertBrand.brandGreen : SearchExpertBrand.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: isSelected ? SearchExpertBrand.brandGreen.opacity(0.40) : .clear,
                                radius: 8, x: 0, y: 0)
                )
        }
        .buttonStyle(.plain)
    }
}
