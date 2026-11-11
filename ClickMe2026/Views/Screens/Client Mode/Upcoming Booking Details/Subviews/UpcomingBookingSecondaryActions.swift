//
//  UpcomingBookingSecondaryActions.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Two-button row: Reschedule (glass) + Cancel (error-tinted)

struct UpcomingBookingSecondaryActions: View {
    /// False once the server would refuse a reschedule (`UpcomingActionPolicy`).
    let showsReschedule: Bool
    /// False once the server would refuse a cancel (`UpcomingActionPolicy`);
    /// Reschedule then fills the row.
    let showsCancel: Bool
    let onReschedule: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showsReschedule {
                rescheduleButton
            }

            if showsCancel {
                cancelButton
            }
        }
    }

    private var rescheduleButton: some View {
        Button(action: onReschedule) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.callout.weight(.regular))
                Text("Reschedule")
                    .font(.brand(.subheadline, weight: .bold))
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
        .buttonStyle(PressScaleButtonStyle())
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle")
                    .font(.callout.weight(.regular))
                Text("Cancel")
                    .font(.brand(.subheadline, weight: .bold))
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
        .buttonStyle(PressScaleButtonStyle())
    }
}
