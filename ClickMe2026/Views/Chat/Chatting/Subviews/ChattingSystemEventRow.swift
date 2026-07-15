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
                    if let sub = event.subtitle {
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
}
