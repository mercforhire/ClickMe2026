//
//  UpcomingBookingDateTimeRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Two-column date + time row

struct UpcomingBookingDateTimeRow: View {
    let date: String
    let timeRange: String

    var body: some View {
        HStack(spacing: 12) {
            cell(icon: "calendar", label: "Date", value: date)
            cell(icon: "clock", label: "Time", value: timeRange)
        }
    }

    private func cell(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
                Text(label)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(UpcomingBookingBrand.onSurfaceVar)
            }
            Text(value)
                .font(.system(size: 16, weight: .regular, design: .rounded))
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(UpcomingBookingGlassCard())
    }
}
