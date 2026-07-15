//
//  BookingConfirmedActionButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct BookingConfirmedActionButtons: View {
    var onAddToCalendar: () -> Void
    var onBackToHome: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Add to Calendar — solid green pill
            Button { onAddToCalendar() } label: {
                Text("Add to Calendar")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Brand.primary)
                            .shadow(color: Brand.primary.opacity(0.45), radius: 14, x: 0, y: 5)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            // Back to Home — dark pill
            Button { onBackToHome() } label: {
                Text("Back to Home")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Brand.onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(Brand.surfaceContainerLow)
                            .overlay(
                                Capsule()
                                    .stroke(Brand.outlineVariant, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(PressScaleButtonStyle())
        }
    }
}

