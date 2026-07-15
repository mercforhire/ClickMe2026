//
//  ExploreCategoryCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExploreCategoryCard: View {
    let category: ExpertCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(category.isSelected ? ExploreBrand.brandGreen.opacity(0.20) : Color(red: 0.14, green: 0.16, blue: 0.16))
                        .frame(width: 48, height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(category.isSelected ? ExploreBrand.brandGreen.opacity(0.60) : Color.clear, lineWidth: 1.5)
                        )

                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(category.isSelected ? ExploreBrand.brandGreen : Color.white.opacity(0.65))
                }

                Text(category.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(category.isSelected ? .white : Color.white.opacity(0.65))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(category.isSelected
                        ? LinearGradient(colors: [Color(red: 0.10, green: 0.26, blue: 0.16),
                                                  Color(red: 0.08, green: 0.18, blue: 0.12)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [ExploreBrand.cardBg, ExploreBrand.cardBg],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(category.isSelected ? ExploreBrand.brandGreen.opacity(0.45) : Color.white.opacity(0.06), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: category.isSelected)
    }
}
