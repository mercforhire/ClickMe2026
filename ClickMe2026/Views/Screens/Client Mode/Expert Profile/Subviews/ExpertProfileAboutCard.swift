//
//  ExpertProfileAboutCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "About" bio card

struct ExpertProfileAboutCard: View {
    let bio: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.body.weight(.regular))
                    .foregroundColor(ExpertProfileBrand.brandGreen)
                Text("About")
                    .font(.brand(.body, weight: .semibold))
                    .foregroundColor(ExpertProfileBrand.onSurface)
            }

            Text(bio)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(ExpertProfileBrand.onSurfaceVar)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertProfileBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ExpertProfileBrand.cardBorder, lineWidth: 1))
        )
    }
}
