//
//  BookingRequestSentActions.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Two stacked action buttons (primary green + dark glass secondary)

struct BookingRequestSentActions: View {
    let onViewBookings: () -> Void
    let onBackToHome: () -> Void
    let opacity: Double
    let yOffset: CGFloat
    /// Gap between the two capsules. The loaded layout keeps 14; the pinned
    /// loading and error placements pass 16 (UI-SPEC section 3).
    var spacing: CGFloat = 14

    var body: some View {
        VStack(spacing: spacing) {
            Button(action: onViewBookings) {
                Text("View My Bookings")
                    .font(.brand(.body, weight: .bold))
                    .foregroundColor(BookingRequestSentBrand.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(BookingRequestSentBrand.brandGreen)
                            .shadow(color: BookingRequestSentBrand.brandGreen.opacity(0.50), radius: 18, x: 0, y: 5)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Button(action: onBackToHome) {
                Text("Back to Home")
                    .font(.brand(.body, weight: .bold))
                    .foregroundColor(BookingRequestSentBrand.onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(BookingRequestSentBrand.secondaryBg)
                            .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1))
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
        .opacity(opacity)
        .offset(y: yOffset)
    }
}
