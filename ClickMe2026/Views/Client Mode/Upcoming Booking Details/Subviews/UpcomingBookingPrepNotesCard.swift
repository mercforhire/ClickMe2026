//
//  UpcomingBookingPrepNotesCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Preparation notes + optional attachment download row

struct UpcomingBookingPrepNotesCard: View {
    let preparationNote: String
    let attachmentName: String?
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PREPARATION NOTES")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                .tracking(1.3)

            Text(preparationNote)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let attachment = attachmentName {
                attachmentRow(attachment)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }

    private func attachmentRow(_ name: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            Text(name)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .lineLimit(1)
            Spacer()
            Button(action: onDownload) {
                Image(systemName: "arrow.down.to.line")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(UpcomingBookingBrand.brandGreen)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(UpcomingBookingBrand.attachBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(UpcomingBookingBrand.attachBorder, lineWidth: 1)
                )
        )
    }
}
