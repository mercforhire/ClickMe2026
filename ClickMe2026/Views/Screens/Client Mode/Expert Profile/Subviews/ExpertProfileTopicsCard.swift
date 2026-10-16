//
//  ExpertProfileTopicsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Topics of Discussion card

struct ExpertProfileTopicsCard: View {
    let topics: [PublicTopic]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Topics of Discussion")
                    .font(.brand(.callout, weight: .semibold))
                    .foregroundColor(ExpertProfileBrand.onSurface)
                Spacer()
            }
            .padding(16)
            .background(ExpertProfileBrand.topicsHeaderBg)

            Divider().background(ExpertProfileBrand.cardBorder)

            ForEach(topics.indices, id: \.self) { i in
                row(topics[i])
                if i < topics.count - 1 {
                    Divider().background(ExpertProfileBrand.cardBorder)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertProfileBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ExpertProfileBrand.cardBorder, lineWidth: 1))
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func row(_ topic: PublicTopic) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(topic.title)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(ExpertProfileBrand.onSurface)
                Text("\(topic.duration) • \(topic.description)")
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(ExpertProfileBrand.onSurfaceVar)
            }
            Spacer()
            Text(topic.price)
                .font(.brand(.subheadline, weight: .bold))
                .foregroundColor(topic.isFree ? ExpertProfileBrand.brandGreen : ExpertProfileBrand.onSurface)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
