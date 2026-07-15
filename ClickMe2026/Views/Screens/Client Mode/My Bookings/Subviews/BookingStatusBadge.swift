//
//  BookingStatusBadge.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Pill-shaped past-booking status badge

struct BookingStatusBadge: View {
    let status: PastBookingStatus

    var body: some View {
        Text(status.label)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
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
