//
//  RescheduleSubmitButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Primary submit button with brand-green glow

struct RescheduleSubmitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Submit Reschedule Request")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RescheduleBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    Capsule()
                        .fill(RescheduleBrand.brandGreen)
                        .shadow(color: RescheduleBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
                )
        }
        .buttonStyle(RescheduleScaleStyle())
    }
}
