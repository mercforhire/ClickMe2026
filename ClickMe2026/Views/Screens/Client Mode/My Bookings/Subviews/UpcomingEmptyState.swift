//
//  UpcomingEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Empty state for the Upcoming tab

struct UpcomingEmptyState: View {
    let glowPulse: Bool
    let onExploreExperts: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            GlowingCalendarIllustration(glowPulse: glowPulse)

            VStack(spacing: 12) {
                Text("No Bookings Yet!")
                    .font(.brand(.title, weight: .bold))
                    .foregroundColor(MyBookingsBrand.onSurface)

                Text("Start your learning journey by finding\nan expert that suits your needs.")
                    .font(.brand(.callout, weight: .regular))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button(action: onExploreExperts) {
                Text("Explore Experts")
                    .font(.brand(.callout, weight: .bold))
                    .foregroundColor(MyBookingsBrand.onPrimary)
                    .frame(width: 220, height: 52)
                    .background(
                        Capsule()
                            .fill(MyBookingsBrand.brandGreen)
                            .shadow(color: MyBookingsBrand.brandGreen.opacity(0.55), radius: 18, x: 0, y: 6)
                    )
            }
            .buttonStyle(PressScaleButtonStyle())

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
