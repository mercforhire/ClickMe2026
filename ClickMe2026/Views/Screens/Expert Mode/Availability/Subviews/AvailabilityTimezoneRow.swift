//
//  AvailabilityTimezoneRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct AvailabilityTimezoneRow: View {
    let selectedTimezone: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(selectedTimezone)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(Brand.onSurface)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.medium))
                    .foregroundColor(Brand.onSurfaceVariant)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.surfaceContainerLow)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Brand.outlineVariant.opacity(0.60), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
