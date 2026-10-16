//
//  BookingStatusBadge.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Pill-shaped past-booking status badge

struct BookingStatusBadge: View {
    let status: PastBookingStatus

    var body: some View {
        Text(status.label)
            .font(.brand(.caption, weight: .semibold))
            .foregroundColor(status.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.12))
                    .overlay(Capsule().stroke(status.color.opacity(0.60), lineWidth: 1))
            )
    }
}
