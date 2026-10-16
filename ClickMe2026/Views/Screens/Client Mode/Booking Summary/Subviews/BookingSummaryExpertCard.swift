//
//  BookingSummaryExpertCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Expert + topic glass card

struct BookingSummaryExpertCard: View {
    let expertName: String
    let expertTitle: String
    let expertImageURL: String
    let topic: String
    let dateTime: String
    /// Formatted total the client paid (e.g. `"$45.00"`). Hidden when nil
    /// — used for free sessions or when the server omitted price fields.
    var pricePaid: String? = nil
    /// Session outcome — drives the status badge in the top-right of
    /// the card. Nil hides the badge (used while loading, or when the
    /// server returns a non-terminal status the summary shouldn't have
    /// been opened for). This replaces the previous hardcoded
    /// "Completed" label, which lied when the booking was actually
    /// missed / cancelled.
    var status: PastBookingStatus? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
                .padding(16)

            Rectangle()
                .fill(BookingSummaryBrand.divider.opacity(0.40))
                .frame(height: 1)
                .padding(.horizontal, 16)

            topicSection
                .padding(16)
        }
        .background(BookingSummaryGlassCardBackground())
    }

    // MARK: Top row

    private var topRow: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .stroke(BookingSummaryBrand.brandGreen, lineWidth: 2)
                    .shadow(color: BookingSummaryBrand.brandGreen.opacity(0.45), radius: 5)
                    .frame(width: 68, height: 68)

                AsyncImage(url: URL(string: expertImageURL)) { phase in
                    switch phase {
                    case let .success(img): img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Color(red: 0.12, green: 0.16, blue: 0.14)
                            Image(systemName: "person.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 62, height: 62)
                .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(expertName)
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(BookingSummaryBrand.onSurface)
                Text(expertTitle)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(BookingSummaryBrand.onSurfaceVar)
            }

            Spacer()

            if let status {
                Text(status.label)
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(status.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(status.color.opacity(0.10))
                            .overlay(Capsule().stroke(status.color.opacity(0.30), lineWidth: 1))
                    )
            }
        }
    }

    // MARK: Topic + date

    private var topicSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("TOPIC")
                .font(.brand(.caption2, weight: .semibold))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                .tracking(1.4)
            Text(topic)
                .font(.brand(.callout, weight: .semibold))
                .foregroundColor(BookingSummaryBrand.brandGreen)
            Text(dateTime)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(BookingSummaryBrand.onSurfaceVar)

            if let pricePaid {
                HStack(spacing: 6) {
                    Text("PAID")
                        .font(.brand(.caption2, weight: .semibold))
                        .foregroundColor(BookingSummaryBrand.onSurfaceVar)
                        .tracking(1.4)
                    Text(pricePaid)
                        .font(.brand(.subheadline, weight: .semibold))
                        .foregroundColor(BookingSummaryBrand.onSurface)
                }
                .padding(.top, 4)
            }
        }
    }
}
