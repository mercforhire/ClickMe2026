//
//  UpcomingBookingPrepNotesCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Client's message-to-expert card
//
// The body renders the `client_notes` string the user attached when they
// booked the session (via `MakeABookingNotesCard`). Label reads
// "YOUR MESSAGE" so it matches the source — this isn't an expert-authored
// prep brief.

struct UpcomingBookingPrepNotesCard: View {
    let preparationNote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YOUR MESSAGE")
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                .tracking(1.3)

            Text(preparationNote)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }
}
