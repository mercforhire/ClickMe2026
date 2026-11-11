//
//  BookingSummaryDeclineNoteCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Decline note card

/// The expert's reason for declining a booking request (BACK-02). Shown on
/// Booking Summary between the expert card and My Note, only for a declined
/// booking with a code or a note (03-UI-SPEC, EM2).
///
/// Never accent or amber: it explains an outcome, it does not ask for an
/// action. The note is expert-authored free text, so it goes to `Text` as a
/// `String` value (no Markdown parsing, no links) and wraps in full (LT1).
struct BookingSummaryDeclineNoteCard: View {
    let note: DeclineNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BookingSummarySectionHeader(icon: "text.bubble", label: "DECLINE NOTE")

            if let reasonLine = note.reasonLine {
                Text(reasonLine)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let text = note.text {
                Text(verbatim: text)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BookingSummaryGlassCardBackground())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Previews

#Preview("Decline note — reason and text") {
    BookingSummaryDeclineNoteCard(
        note: DeclineNote(
            reasonLine: "Not available at that time",
            text: "I'm travelling that whole week and won't have a reliable connection. "
                + "Please try again after the 20th, when I'm back and can give you a proper session."
        )
    )
    .padding(20)
    .background(BookingSummaryBrand.bg)
    .preferredColorScheme(.dark)
}

#Preview("Decline note — text only") {
    BookingSummaryDeclineNoteCard(
        note: DeclineNote(reasonLine: nil, text: "Sorry, this isn't a good fit for me.")
    )
    .padding(20)
    .background(BookingSummaryBrand.bg)
    .preferredColorScheme(.dark)
}
