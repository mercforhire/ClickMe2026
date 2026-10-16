//
//  ClientProfileBookingHistory.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Booking History" section wrapping a stack of booking cards

struct ClientProfileBookingHistory: View {
    let bookingHistory: [ClientBookingHistory]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Booking History")
                .font(.brand(.title2, weight: .bold))
                .foregroundColor(ClientProfileBrand.onSurface)

            VStack(spacing: 12) {
                ForEach(bookingHistory) { booking in
                    ClientProfileBookingCard(booking: booking)
                }
            }
        }
    }
}
