//
//  BookingConfirmedActionButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct BookingConfirmedActionButtons: View {
    let booking: BookingConfirmation
    var onAddToCalendar: (BookingConfirmation) -> Void
    var onBackToHome: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Add to Calendar — solid green pill
            Button { onAddToCalendar(booking) } label: {
                Text("Add to Calendar")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(BookingConfirmedTheme.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(BookingConfirmedTheme.brandGreen)
                            .shadow(color: BookingConfirmedTheme.brandGreen.opacity(0.45), radius: 14, x: 0, y: 5)
                    )
            }
            .buttonStyle(ConfirmScaleStyle())

            // Back to Home — dark pill
            Button { onBackToHome() } label: {
                Text("Back to Home")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(BookingConfirmedTheme.onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(BookingConfirmedTheme.cardBg)
                            .overlay(
                                Capsule()
                                    .stroke(BookingConfirmedTheme.divider, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(ConfirmScaleStyle())
        }
    }
}

private struct ConfirmScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
