//
//  BookingConfirmedCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct BookingConfirmedCard: View {
    let booking: BookingConfirmation

    var body: some View {
        VStack(spacing: 0) {
            // Expert row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.expertName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(BookingConfirmedTheme.onSurface)
                    Text(booking.expertTitle)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(BookingConfirmedTheme.muted)
                }

                Spacer()

                AsyncImage(url: URL(string: booking.expertImageURL)) { phase in
                    switch phase {
                    case let .success(img):
                        img.resizable().scaledToFill()
                    default:
                        ZStack {
                            Circle().fill(Color(red: 0.14, green: 0.20, blue: 0.16))
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
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
                .fill(BookingConfirmedTheme.divider)
                .frame(height: 1)
                .padding(.bottom, 16)

            // Date & meeting type rows
            VStack(alignment: .leading, spacing: 12) {
                iconRow(
                    icon: "calendar",
                    label: "\(booking.date), \(booking.time) (\(booking.duration))"
                )
                iconRow(
                    icon: booking.isVirtual ? "video" : "person.2",
                    label: booking.meetingNote
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(BookingConfirmedTheme.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(BookingConfirmedTheme.divider, lineWidth: 1)
                )
        )
    }

    private func iconRow(icon: String, label: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(BookingConfirmedTheme.muted)
                .frame(width: 22)
            Text(label)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(BookingConfirmedTheme.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
