//
//  CancellationDeadlinesCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Card 1 — Cancellation Deadlines

struct CancellationDeadlinesCard: View {
    var body: some View {
        PolicyCard(border: CancellationPoliciesBrand.greenTealBorder) {
            VStack(alignment: .leading, spacing: 20) {
                PolicyCardTitle("Cancellation Deadlines")

                VStack(alignment: .leading, spacing: 16) {
                    deadlineRow(
                        title: "More than 24 hours before the start",
                        subtitle: "Not charged, or a full refund if already charged"
                    )
                    deadlineRow(
                        title: "Within 24 hours of the start",
                        subtitle: "Not charged, but no refund if already charged"
                    )
                    deadlineRow(
                        title: "After the session ends",
                        subtitle: "Can't be cancelled; charged if the session went ahead"
                    )
                }
            }
        }
    }

    private func deadlineRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "clock")
                .font(.title3.weight(.regular))
                .foregroundColor(CancellationPoliciesBrand.brandGreen)
                .frame(width: 24, height: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(CancellationPoliciesBrand.onSurface)
                Text(subtitle)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(CancellationPoliciesBrand.onSurfaceVar)
            }
        }
    }
}
