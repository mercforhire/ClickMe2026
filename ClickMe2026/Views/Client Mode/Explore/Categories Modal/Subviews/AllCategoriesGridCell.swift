//
//  AllCategoriesGridCell.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single category grid cell

struct AllCategoriesGridCell: View {
    let category: AllCategoriesView.CategoryItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(category.isSelected ? AllCategoriesBrand.brandGreen : AllCategoriesBrand.onSurface)
                    .shadow(color: category.isSelected ? AllCategoriesBrand.brandGreen.opacity(0.60) : .clear, radius: 8)
                    .frame(height: 44)

                Text(category.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(category.isSelected ? AllCategoriesBrand.brandGreen : AllCategoriesBrand.onSurface)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        category.isSelected
                            ? Color(red: 0.08, green: 0.18, blue: 0.11)
                            : AllCategoriesBrand.cardBg
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                category.isSelected ? AllCategoriesBrand.brandGreen.opacity(0.65) : Color.white.opacity(0.07),
                                lineWidth: category.isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: category.isSelected ? AllCategoriesBrand.brandGreen.opacity(0.18) : .clear,
                        radius: 10, x: 0, y: 0
                    )
            )
        }
        .buttonStyle(CatCellScaleStyle())
        .animation(.easeInOut(duration: 0.2), value: category.isSelected)
    }
}
