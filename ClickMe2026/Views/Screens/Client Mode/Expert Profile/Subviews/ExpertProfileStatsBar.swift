//
//  ExpertProfileStatsBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Exp / Bookings stats bar

struct ExpertProfileStatsBar: View {
    let yearsExp: String
    let bookings: String

    var body: some View {
        HStack(spacing: 10) {
            cell(label: "Exp.", value: yearsExp)
            cell(label: "Bookings", value: bookings)
        }
    }

    private func cell(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.brand(.caption2, weight: .medium))
                .foregroundColor(ExpertProfileBrand.onSurfaceVar)
            Text(value)
                .font(.brand(.subheadline, weight: .bold))
                .foregroundColor(ExpertProfileBrand.onSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(ExpertProfileBrand.surfaceContainer)
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(ExpertProfileBrand.cardBorder, lineWidth: 1))
        )
    }
}
