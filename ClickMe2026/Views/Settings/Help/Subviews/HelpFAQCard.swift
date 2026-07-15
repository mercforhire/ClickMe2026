//
//  HelpFAQCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - FAQ category card with iridescent border + expandable Q&A

struct HelpFAQCard: View {
    let category: HelpFAQCategory
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            Button(action: onTap) {
                HStack {
                    Text(category.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(HelpBrand.onSurface)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(HelpBrand.onSurfaceVar)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .contentShape(Rectangle())
            }
            .buttonStyle(HelpScaleStyle())

            // Expanded Q&A list
            if isExpanded {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(category.items) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.question)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(HelpBrand.onSurface)
                            Text(item.answer)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(HelpBrand.onSurfaceVar)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(HelpBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(HelpBrand.iridBorder, lineWidth: 1.2)
                )
        )
    }
}
