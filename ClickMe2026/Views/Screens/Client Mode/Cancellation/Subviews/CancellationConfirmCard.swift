//
//  CancellationConfirmCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Confirmation glass card (warning + title + booking summary + refund note)

struct CancellationConfirmCard: View {
    let booking: CancellationBooking

    var body: some View {
        VStack(spacing: 20) {
            warningIcon

            VStack(spacing: 8) {
                Text("Confirm Cancellation?")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(CancellationBrand.onSurface)
                Text("Please review the booking details below before confirming.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(CancellationBrand.onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            CancellationBookingSummary(booking: booking)

            Text("Refunds typically appear in your account within 3–5 business days.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(CancellationBrand.outlineVar)
                .italic()
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CancellationBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(CancellationBrand.cardBorder, lineWidth: 1))
        )
    }

    private var warningIcon: some View {
        ZStack {
            Circle()
                .fill(CancellationBrand.brandGreen.opacity(0.10))
                .overlay(Circle().stroke(CancellationBrand.brandGreen.opacity(0.30), lineWidth: 1))
                .frame(width: 64, height: 64)
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 30, weight: .light))
                .foregroundColor(CancellationBrand.brandGreen)
                .shadow(color: CancellationBrand.brandGreen.opacity(0.50), radius: 8)
        }
    }
}
