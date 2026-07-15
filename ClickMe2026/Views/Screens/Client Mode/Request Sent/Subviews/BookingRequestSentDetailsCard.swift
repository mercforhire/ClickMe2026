//
//  BookingRequestSentDetailsCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking details card: topic + date/time + amber status pill

struct BookingRequestSentDetailsCard: View {
    let topic: String
    let dateTime: String
    let opacity: Double
    let yOffset: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel

            topicRow
            dividerLine

            dateTimeRow
            dividerLine

            statusRow
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(BookingRequestSentBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(BookingRequestSentBrand.divider, lineWidth: 1)
                )
        )
        .opacity(opacity)
        .offset(y: yOffset)
    }

    // MARK: Rows

    private var sectionLabel: some View {
        Text("BOOKING DETAILS")
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
            .tracking(1.5)
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 16)
    }

    private var topicRow: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Topic")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
                Text(topic)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(BookingRequestSentBrand.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(BookingRequestSentBrand.iconBoxBg)
                    .frame(width: 44, height: 44)
                Image(systemName: "square.3.layers.3d")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(BookingRequestSentBrand.brandGreen)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
    }

    private var dateTimeRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Date & Time")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
                Text(dateTime)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(BookingRequestSentBrand.onSurface)
            }
            Spacer()
            Image(systemName: "calendar")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var statusRow: some View {
        HStack {
            Text("Status")
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
            Spacer()
            statusPill
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(BookingRequestSentBrand.divider.opacity(0.40))
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private var statusPill: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(BookingRequestSentBrand.amberDot)
                .frame(width: 8, height: 8)
                .shadow(color: BookingRequestSentBrand.amberDot.opacity(0.70), radius: 4)
            Text("Awaiting Approval")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(BookingRequestSentBrand.onSurfaceVar)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(BookingRequestSentBrand.statusBg)
                .overlay(Capsule().stroke(BookingRequestSentBrand.statusBorder, lineWidth: 1))
        )
    }
}
