//
//  BookingConfirmedCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct BookingConfirmedCard: View {
    let booking: BookingConfirmation

    var body: some View {
        VStack(spacing: 0) {
            // Client row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.clientName)
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(Brand.onSurface)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(booking.topic)
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                AsyncImage(url: URL(string: booking.clientImageURL)) { phase in
                    switch phase {
                    case let .success(img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Circle().fill(Color(red: 0.14, green: 0.20, blue: 0.16))
                            Image(systemName: "person.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.15))
                        }
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            }
            .padding(.bottom, 16)

            // Divider
            Rectangle()
                .fill(Brand.outlineVariant)
                .frame(height: 1)
                .padding(.bottom, 16)

            // Date & meeting type rows
            VStack(alignment: .leading, spacing: 12) {
                iconRow(
                    icon: "calendar",
                    label: "\(booking.date), \(booking.time) (\(booking.duration))"
                )
                iconRow(
                    icon: booking.meetingTypeIcon,
                    label: booking.meetingTypeLabel
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Brand.outlineVariant, lineWidth: 1)
                )
        )
    }

    private func iconRow(icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3.weight(.regular))
                .foregroundColor(Brand.onSurfaceVariant)
                .frame(width: 22)
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
