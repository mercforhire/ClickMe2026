//
//  UpcomingBookingSecondaryActions.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Two-button row: Reschedule (glass) + Cancel (error-tinted)

struct UpcomingBookingSecondaryActions: View {
    let onReschedule: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onReschedule) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise.circle")
                        .font(.system(size: 16, weight: .regular))
                    Text("Reschedule")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(UpcomingBookingBrand.onSurface)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(UpcomingBookingBrand.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(UpcomingBookingBrand.cardBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(DetailsScaleStyle())

            Button(action: onCancel) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 16, weight: .regular))
                    Text("Cancel")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(UpcomingBookingBrand.errorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(UpcomingBookingBrand.errorColor.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(UpcomingBookingBrand.errorColor.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(DetailsScaleStyle())
        }
    }
}
