//
//  MakeABookingSummarySection.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct MakeABookingSummarySection: View {
    let topicLabel: String
    let dateTimeLabel: String
    let durationLabel: String
    let meetingTypeLabel: String
    let priceLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            MakeABookingSectionHeader(title: "Summary")

            VStack(spacing: 8) {
                row(label: "Topic:", value: topicLabel)
                row(label: "Date & Time:", value: dateTimeLabel)
                row(label: "Duration:", value: durationLabel)
                row(label: "Meeting Type:", value: meetingTypeLabel)
                row(label: "Price:", value: priceLabel)
            }
        }
    }

    private func row(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(MakeABookingBrand.onSurfaceVar)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(MakeABookingBrand.onSurface)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
