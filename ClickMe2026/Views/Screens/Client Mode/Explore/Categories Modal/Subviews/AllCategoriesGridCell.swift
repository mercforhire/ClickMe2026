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
    let category: Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: CategoryIconMap.sfSymbol(forSlug: category.id))
                    .font(.system(size: 36, weight: .thin))
                    .foregroundColor(isSelected ? AllCategoriesBrand.brandGreen : AllCategoriesBrand.onSurface)
                    .shadow(color: isSelected ? AllCategoriesBrand.brandGreen.opacity(0.60) : .clear, radius: 8)
                    .frame(height: 44)

                Text(category.name)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(isSelected ? AllCategoriesBrand.brandGreen : AllCategoriesBrand.onSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        isSelected
                            ? Color(red: 0.08, green: 0.18, blue: 0.11)
                            : AllCategoriesBrand.cardBg
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(
                                isSelected ? AllCategoriesBrand.brandGreen.opacity(0.65) : Color.white.opacity(0.07),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? AllCategoriesBrand.brandGreen.opacity(0.18) : .clear,
                        radius: 10, x: 0, y: 0
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}
