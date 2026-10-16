//
//  RescheduleSubmitButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Primary submit button with brand-green glow

struct RescheduleSubmitButton: View {
    let action: () -> Void
    /// Swaps the label for a spinner + "Submitting…" while the network
    /// call is in flight, so the user gets visible feedback instead of
    /// wondering whether the tap registered.
    var isLoading: Bool = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .tint(RescheduleBrand.onPrimary)
                        .controlSize(.small)
                    Text("Submitting…")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(RescheduleBrand.onPrimary)
                } else {
                    Text("Submit Reschedule Request")
                        .font(.brand(.callout, weight: .bold))
                        .foregroundColor(RescheduleBrand.onPrimary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                Capsule()
                    .fill(RescheduleBrand.brandGreen)
                    .shadow(color: RescheduleBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
