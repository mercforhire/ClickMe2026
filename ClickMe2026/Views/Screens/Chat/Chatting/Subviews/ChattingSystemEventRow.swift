//
//  ChattingSystemEventRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking / system event row

struct ChattingSystemEventRow: View {
    let event: BookingEvent

    /// Renders "Fri, Jul 19 · 2:17 PM". Locale-aware and cached so we
    /// don't rebuild the formatter for every row in a long chat.
    private static let bookingTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEE, MMM d · h:mm a")
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            if let url = event.avatarURL {
                ChattingAvatar(url: url, size: 34)
            }

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ChattingBrand.systemBg)
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(ChattingBrand.systemBorder, lineWidth: 1))
                        .frame(width: 36, height: 36)

                    Image(systemName: event.icon)
                        .font(.system(size: 16, weight: event.isAccepted ? .semibold : .regular))
                        .foregroundColor(event.isAccepted ? ChattingBrand.brandGreen : ChattingBrand.onSurface)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(ChattingBrand.onSurface)

                    if let topic = event.topicTitle, !topic.isEmpty {
                        Text(bookingSubtitle(topic: topic))
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(ChattingBrand.onSurfaceVar)
                            .lineLimit(2)
                    } else if let sub = event.subtitle {
                        // Legacy path — pre-enrichment events fall back
                        // to the server-provided content string.
                        Text(sub)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(ChattingBrand.onSurfaceVar)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ChattingBrand.systemBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ChattingBrand.systemBorder, lineWidth: 1))
            )
        }
    }

    /// Composes the "<topic> · <weekday, date · time>" line beneath the
    /// event title. Falls back to just the topic when start time is
    /// missing (legacy rows) so the row never renders "topic · ".
    private func bookingSubtitle(topic: String) -> String {
        guard let start = event.startTime else { return topic }
        return "\(topic) · \(Self.bookingTimeFormatter.string(from: start))"
    }
}
