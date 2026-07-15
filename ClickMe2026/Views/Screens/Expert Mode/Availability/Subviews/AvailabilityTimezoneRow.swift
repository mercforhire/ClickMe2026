//
//  AvailabilityTimezoneRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct AvailabilityTimezoneRow: View {
    let selectedTimezone: String
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(selectedTimezone)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Brand.onSurface)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 13, weight: .medium))
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
