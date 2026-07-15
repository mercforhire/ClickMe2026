//
//  ClientProfileBookingCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single booking-history card with status icon, title, amount

struct ClientProfileBookingCard: View {
    let booking: ClientBookingHistory

    var body: some View {
        HStack(spacing: 14) {
            statusIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(booking.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurface)
                    .lineLimit(1)

                Text("\(booking.status.label) - \(booking.date)")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(ClientProfileBrand.onSurfaceVar)
            }

            Spacer()

            Text("$\(booking.amount)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(ClientProfileBrand.onSurface)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ClientProfileBrand.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            booking.status == .upcoming
                                ? ClientProfileBrand.brandGreen.opacity(0.55)
                                : ClientProfileBrand.outlineVar,
                            lineWidth: booking.status == .upcoming ? 1.2 : 1
                        )
                        .shadow(
                            color: booking.status == .upcoming
                                ? ClientProfileBrand.brandGreen.opacity(0.20)
                                : .clear,
                            radius: 6, x: 0, y: 0
                        )
                )
        )
    }

    private var statusIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(booking.status.tint.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(booking.status.tint.opacity(0.45), lineWidth: 1)
                )
                .frame(width: 44, height: 44)

            Image(systemName: booking.status.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(booking.status.tint)
        }
    }
}
