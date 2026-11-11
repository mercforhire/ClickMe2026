//
//  PastEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Empty state for the Past tab

/// Shown when the bookings load succeeded and there are no past bookings
/// (BOOK-11, UI-SPEC EM1). A sibling of `UpcomingEmptyState`: same
/// illustration and layout, no button, because there is nothing to start from
/// here. The title is 22 pt semibold by UI-SPEC design (4 sizes, 2 weights),
/// not the Upcoming tab's 28 pt bold.
struct PastEmptyState: View {
    let glowPulse: Bool

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            GlowingCalendarIllustration(glowPulse: glowPulse)

            VStack(spacing: 12) {
                Text("No past bookings yet")
                    .font(.brand(.title2, weight: .semibold))
                    .foregroundColor(Brand.onSurface)

                Text("Completed, cancelled and missed sessions will show up here.")
                    .font(.brand(.callout, weight: .regular))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Previews

#Preview("Past Empty State") {
    ZStack {
        MyBookingsBrand.bg.ignoresSafeArea()
        PastEmptyState(glowPulse: true)
    }
    .preferredColorScheme(.dark)
}
