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
    let categories: [String]
    @Binding var selectedCategory: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { cat in
                    chip(cat)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chip(_ cat: String) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                selectedCategory = cat
            }
        } label: {
            Text(cat)
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
