//
//  UpcomingBookingTopicCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Session topic + consultation fee

struct UpcomingBookingTopicCard: View {
    let topic: String
    let consultationFee: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION TOPIC")
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                .tracking(1.3)

            Text(topic)
                .font(.brand(.title3, weight: .semibold))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(UpcomingBookingBrand.divider.opacity(0.40))
                .frame(height: 1)

            HStack {
                Text("Total Paid")
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                Spacer()
                Text(consultationFee)
                    .font(.brand(.title3, weight: .semibold))
                    .foregroundColor(UpcomingBookingBrand.brandGreen)
            }
        }
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }
}
