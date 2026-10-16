//
//  BookingConfirmedHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct BookingConfirmedHeadline: View {
    let booking: BookingConfirmation

    var body: some View {
        VStack(spacing: 12) {
            Text("Booking Confirmed!")
                .font(.brand(.title, weight: .bold))
                .foregroundColor(Brand.onSurface)
                .multilineTextAlignment(.center)

            Text("Your meeting with \(booking.expertName) on \(booking.date), at \(booking.time) has been successfully booked.")
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
