//
//  ExpertCancellationActions.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Keep Booking + Confirm Cancellation button stack

struct ExpertCancellationActions: View {
    let isCancelling: Bool
    let onKeepBooking: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Button(action: onKeepBooking) {
                Text("Keep Booking")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(ExpertCancellationBrand.onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule()
                            .fill(ExpertCancellationBrand.brandGreen)
                            .shadow(color: ExpertCancellationBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
                    )
            }
            .buttonStyle(CancelViewScale())

            Button(action: onConfirm) {
                HStack(spacing: 8) {
                    if isCancelling {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: ExpertCancellationBrand.errorColor))
                    } else {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 17, weight: .regular))
                        Text("Confirm Cancellation")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(ExpertCancellationBrand.errorColor)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule()
                        .fill(Color.clear)
                        .overlay(Capsule().stroke(ExpertCancellationBrand.errorBorder, lineWidth: 1.5))
                )
            }
            .buttonStyle(CancelViewScale())
            .disabled(isCancelling)
        }
    }
}
