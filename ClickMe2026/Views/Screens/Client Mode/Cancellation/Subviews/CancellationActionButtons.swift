//
//  CancellationActionButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Step 2 action buttons — Keep Booking + Confirm Cancellation

struct CancellationActionButtons: View {
    let isConfirming: Bool
    let onKeepBooking: () -> Void
    let onConfirmCancellation: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            keepBookingButton
            confirmCancellationButton
        }
    }

    private var keepBookingButton: some View {
        Button(action: onKeepBooking) {
            Text("Keep Booking")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(CancellationBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(CancellationBrand.brandGreen)
                        .shadow(color: CancellationBrand.brandGreen.opacity(0.45), radius: 16, x: 0, y: 5)
                )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var confirmCancellationButton: some View {
        Button(action: onConfirmCancellation) {
            HStack(spacing: 8) {
                if isConfirming {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: CancellationBrand.errorColor))
                } else {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 17, weight: .regular))
                    Text("Confirm Cancellation")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .foregroundColor(CancellationBrand.errorColor)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(CancellationBrand.errorColor.opacity(0.06))
                    .overlay(Capsule().stroke(CancellationBrand.errorBorder, lineWidth: 1.5))
            )
        }
        .buttonStyle(PressScaleButtonStyle())
        .disabled(isConfirming)
    }
}
