//
//  BookingSummaryResources.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Session resources — Call Recording / Shared Notes tiles

struct BookingSummaryResources: View {
    let onCallRecording: () -> Void
    let onSharedNotes: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookingSummarySectionHeader(icon: "paperclip", label: "SESSION RESOURCES")

            HStack(spacing: 12) {
                tile(icon: "video", label: "Call Recording", action: onCallRecording)
                tile(icon: "doc.text", label: "Shared Notes", action: onSharedNotes)
            }
        }
    }

    private func tile(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .thin))
                    .foregroundColor(BookingSummaryBrand.brandGreen)
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(BookingSummaryBrand.onSurface)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BookingSummaryBrand.resourceBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(BookingSummaryBrand.cardBorder, lineWidth: 1))
            )
        }
        .buttonStyle(SummaryScaleStyle())
    }
}
