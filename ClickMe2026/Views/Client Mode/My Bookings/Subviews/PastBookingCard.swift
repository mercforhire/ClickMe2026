//
//  PastBookingCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Single past booking card

struct PastBookingCard: View {
    let booking: PastBooking
    let onViewSummary: () -> Void
    let onPrivateNote: () -> Void
    let onLeaveReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(booking.expertName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(MyBookingsBrand.onSurface)
                Spacer()
                BookingStatusBadge(status: booking.status)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Topic:")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(MyBookingsBrand.onSurfaceVar)
                    Text(booking.topic)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(MyBookingsBrand.onSurface)
                }
                Text("\(booking.date), \(booking.timeRange)")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar)
            }

            actionsRow
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MyBookingsBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(MyBookingsBrand.cardBorder, lineWidth: 1))
        )
    }

    private var actionsRow: some View {
        HStack(spacing: 0) {
            Button(action: onViewSummary) {
                Text("View Summary")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MyBookingsBrand.brandGreen)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: onPrivateNote) {
                HStack(spacing: 5) {
                    Text("Private Note")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(MyBookingsBrand.brandGreen)
                }
            }
            .buttonStyle(.plain)

            if booking.status == .completed {
                Spacer()
                Button(action: onLeaveReview) {
                    Text("Leave Review")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(MyBookingsBrand.onPrimary)
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(
                            Capsule()
                                .fill(MyBookingsBrand.brandGreen)
                                .shadow(color: MyBookingsBrand.brandGreen.opacity(0.45), radius: 8)
                        )
                }
                .buttonStyle(BookingScaleStyle())
            }
        }
    }
}
