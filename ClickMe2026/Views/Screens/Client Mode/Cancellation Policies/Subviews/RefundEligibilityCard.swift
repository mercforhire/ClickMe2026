//
//  RefundEligibilityCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
                        title: "Not Charged",
                        body: "Your card is only held until the session ends. Cancel before then and the hold is released, so you pay nothing. The same applies if the expert cancels or doesn't show up."
                    )
                    refundRow(
                        icon: "checkmark",
                        iconColor: CancellationPoliciesBrand.brandGreen,
                        title: "Full Refund",
                        body: "If your card was already charged (for example, after a reschedule) and you cancel more than 24 hours before the start, you get a full refund to the same card."
                    )
                    refundRow(
                        icon: "xmark",
                        iconColor: CancellationPoliciesBrand.errorRed,
                        title: "No Refund",
                        body: "No refund if your card was already charged and you cancel within 24 hours of the start, or if the expert joins and you don't."
                    )
                }
            }
        }
    }

    private func refundRow(icon: String, iconColor: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.callout.weight(.semibold))
                .foregroundColor(iconColor)
                .frame(width: 22, height: 22)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(CancellationPoliciesBrand.onSurface)
                Text(body)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(CancellationPoliciesBrand.onSurfaceVar)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
