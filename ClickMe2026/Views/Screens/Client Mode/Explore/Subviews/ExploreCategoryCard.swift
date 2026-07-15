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
            VStack(alignment: .leading, spacing: 12) {
                iconBadge

                Text(category.name)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(category.isSelected ? .white : Color.white.opacity(0.75))
                    .lineLimit(1)
            }
            .frame(width: 96, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(cardBackground)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: category.isSelected)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(category.isSelected
                    ? ExploreBrand.brandGreen.opacity(0.22)
                    : Color(red: 0.14, green: 0.18, blue: 0.16))
                .frame(width: 36, height: 36)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(category.isSelected ? ExploreBrand.brandGreen.opacity(0.55) : Color.clear, lineWidth: 1)
                )

            Image(systemName: category.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(category.isSelected ? ExploreBrand.brandGreen : Color.white.opacity(0.75))
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(category.isSelected
                ? LinearGradient(colors: [Color(red: 0.10, green: 0.26, blue: 0.16),
                                          Color(red: 0.08, green: 0.18, blue: 0.12)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing)
                : LinearGradient(colors: [ExploreBrand.cardBg, ExploreBrand.cardBg],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(category.isSelected
                        ? ExploreBrand.brandGreen.opacity(0.45)
                        : Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}
