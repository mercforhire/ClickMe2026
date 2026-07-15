//
//  BookingConfirmedHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct BookingConfirmedHeadline: View {
    let booking: BookingConfirmation

    var body: some View {
        VStack(spacing: 12) {
            Text("Booking Confirmed!")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(BookingConfirmedTheme.onSurface)
                .multilineTextAlignment(.center)

            Text("Your meeting with \(booking.expertName) on \(booking.date), at \(booking.time) has been successfully booked.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(BookingConfirmedTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }
}
