//
//  UpcomingBookingTopicCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Session topic + consultation fee

struct UpcomingBookingTopicCard: View {
    let topic: String
    let consultationFee: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SESSION TOPIC")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                .tracking(1.3)

            Text(topic)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(UpcomingBookingBrand.divider.opacity(0.40))
                .frame(height: 1)

            HStack {
                Text("Consultation Fee")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                Spacer()
                Text(consultationFee)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.brandGreen)
            }
        }
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }
}
