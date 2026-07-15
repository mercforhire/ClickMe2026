//
//  UpcomingBookingStatusRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Confirmed" pill + right-aligned booking ID

struct UpcomingBookingStatusRow: View {
    let bookingID: String

    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(UpcomingBookingBrand.brandGreen)
                    .frame(width: 8, height: 8)
                    .shadow(color: UpcomingBookingBrand.brandGreen.opacity(0.80), radius: 4)
                Text("Confirmed")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.brandGreen)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(UpcomingBookingBrand.brandGreen.opacity(0.10))
                    .overlay(Capsule().stroke(UpcomingBookingBrand.brandGreen.opacity(0.30), lineWidth: 1))
            )

            Spacer()

            Text("ID: \(bookingID)")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
        }
    }
}
