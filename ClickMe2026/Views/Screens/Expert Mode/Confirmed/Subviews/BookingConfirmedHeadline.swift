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

            Text(ExpertBookingConfirmationContent.bodySentence(
                clientName: booking.clientName,
                date: booking.date,
                time: booking.time
            ))
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurfaceVariant)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
