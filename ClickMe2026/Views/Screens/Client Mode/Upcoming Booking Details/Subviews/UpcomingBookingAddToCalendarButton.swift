//
//  UpcomingBookingAddToCalendarButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Add to Calendar (G-06-1-summary-calendar)

/// Full-width Add to Calendar button in the same glass style as Reschedule.
/// The screen decides when it shows; the tap opens the system New Event sheet.
struct UpcomingBookingAddToCalendarButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.callout.weight(.regular))
                Text("Add to Calendar")
                    .font(.brand(.subheadline, weight: .bold))
            }
            .foregroundColor(UpcomingBookingBrand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(UpcomingBookingBrand.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(UpcomingBookingBrand.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}

#Preview("Add to Calendar") {
    ZStack {
        UpcomingBookingBrand.bg.ignoresSafeArea()
        UpcomingBookingAddToCalendarButton(onTap: {})
            .padding(.horizontal, 20)
    }
}
