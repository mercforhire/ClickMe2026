//
//  RefundEligibilityCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Card 2 — Refund Eligibility

struct RefundEligibilityCard: View {
    var body: some View {
        PolicyCard(border: CancellationPoliciesBrand.purpleTealBorder) {
            VStack(alignment: .leading, spacing: 20) {
                PolicyCardTitle("Refund Eligibility")

                VStack(alignment: .leading, spacing: 18) {
                    refundRow(
                        icon: "checkmark",
                        iconColor: CancellationPoliciesBrand.brandGreen,
                        title: "Full Refund",
                        body: "Cancellations made more than 24 hours before the scheduled meeting are eligible for a full refund, processed within 5–7 business days."
                    )
                    refundRow(
                        icon: "checkmark",
                        iconColor: CancellationPoliciesBrand.brandGreen,
                        title: "Partial Refund",
                        body: "Cancellations within 24 hours of the meeting may receive a partial refund at the expert's discretion, typically 50% of the session fee."
                    )
                    refundRow(
                        icon: "xmark",
                        iconColor: CancellationPoliciesBrand.errorRed,
                        title: "No Refund",
                        body: "No refund is issued for cancellations after the meeting has started, or for no-shows without prior notice."
                    )
                }
            }
        }
    }

    private func refundRow(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 22, height: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(CancellationPoliciesBrand.onSurface)
                Text(body)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(CancellationPoliciesBrand.onSurfaceVar)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
