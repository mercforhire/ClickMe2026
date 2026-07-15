//
//  ExpertProfileExpertiseSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expertise tag pills

struct ExpertProfileExpertiseSection: View {
    let tags: [PublicExpertTag]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Expertise")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(ExpertProfileBrand.onSurface)

            ExpertFlowLayoutView(spacing: 8) {
                ForEach(tags, id: \.label) { tag in
                    tagPill(tag)
                }
            }
        }
    }

    private func tagPill(_ tag: PublicExpertTag) -> some View {
        Text(tag.label)
            .font(.system(size: 13, weight: .medium, design: .rounded))
            .foregroundColor(tag.isHighlighted ? ExpertProfileBrand.brandGreen : ExpertProfileBrand.onSurfaceVar)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(tag.isHighlighted ? ExpertProfileBrand.brandGreen.opacity(0.10) : ExpertProfileBrand.tagBg)
                    .overlay(
                        Capsule()
                            .stroke(tag.isHighlighted ? ExpertProfileBrand.brandGreen : ExpertProfileBrand.outlineVar, lineWidth: 1)
                            .shadow(color: tag.isHighlighted ? ExpertProfileBrand.brandGreen.opacity(0.20) : .clear,
                                    radius: 4)
                    )
            )
    }
}
