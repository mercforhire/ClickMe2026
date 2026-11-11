//
//  UpcomingBookingStatusRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Status pill + right-aligned booking ID

/// The pill shows the booking's real status (BOOK-09); the ID sits on the right.
/// Both read as one VoiceOver element.
struct UpcomingBookingStatusRow: View {
    let pill: BookingStatusPill
    let bookingID: String

    private var tint: Color {
        switch pill.tone {
        case .accent: return UpcomingBookingBrand.brandGreen
        case .amber: return Color.orange
        case .neutral: return UpcomingBookingBrand.onSurfaceVar
        }
    }

    var body: some View {
        HStack {
            HStack(spacing: 7) {
                Circle()
                    .fill(tint)
                    .frame(width: 8, height: 8)
                    .shadow(color: tint.opacity(0.80), radius: 4)
                Text(pill.text)
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(tint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(tint.opacity(0.10))
                    .overlay(Capsule().stroke(tint.opacity(0.30), lineWidth: 1))
            )

            Spacer()

            Text("ID: \(bookingID)")
                .font(.brand(.caption, weight: .medium))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
        }
        .accessibilityElement(children: .combine)
    }
}
