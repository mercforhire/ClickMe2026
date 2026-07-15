//
//  CancellationDeadlinesCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
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
                        title: "24 hours before the meeting",
                        subtitle: "Full refund"
                    )
                    deadlineRow(
                        title: "Within 24 hours of the meeting",
                        subtitle: "Partial refund"
                    )
                    deadlineRow(
                        title: "After the meeting has started",
                        subtitle: "No refund"
                    )
                }
            }
        }
    }

    private func deadlineRow(title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(CancellationPoliciesBrand.brandGreen)
                .frame(width: 24, height: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(CancellationPoliciesBrand.onSurface)
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(CancellationPoliciesBrand.onSurfaceVar)
            }
        }
    }
}
