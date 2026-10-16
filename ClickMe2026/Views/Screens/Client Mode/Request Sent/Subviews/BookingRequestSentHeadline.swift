//
//  BookingRequestSentHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Request Sent!" title + body copy with inline expert name

struct BookingRequestSentHeadline: View {
    let expertName: String
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        VStack(spacing: 14) {
            Text("Request Sent!")
                .font(.brand(.title, weight: .bold))
                .foregroundColor(BookingRequestSentBrand.onSurface)

            (
                Text("Your booking request has been sent to ")
                    .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
                    + Text(expertName)
                    .foregroundColor(BookingRequestSentBrand.brandGreen)
                    .fontWeight(.semibold)
                    + Text(". They will review it and respond shortly. You'll be notified as soon as it's confirmed.")
                    .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
            )
            .font(.brand(.callout, weight: .regular))
            .multilineTextAlignment(.center)
            .lineSpacing(4)
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
