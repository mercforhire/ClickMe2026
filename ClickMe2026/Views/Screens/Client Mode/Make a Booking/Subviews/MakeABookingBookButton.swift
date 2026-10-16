//
//  MakeABookingBookButton.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct MakeABookingBookButton: View {
    let title: String
    let isBooking: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MakeABookingBrand.brandGreen)
                    .shadow(color: MakeABookingBrand.brandGreen.opacity(isEnabled ? 0.45 : 0.10), radius: 16, x: 0, y: 4)
                    .frame(height: 56)
                    .opacity(isEnabled ? 1 : 0.5)

                if isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: MakeABookingBrand.onPrimary))
                } else {
                    Text(title)
                        .font(.brand(.body, weight: .bold))
                        .foregroundColor(MakeABookingBrand.onPrimary)
                }
            }
        }
        .frame(height: 56)
        .disabled(!isEnabled || isBooking)
        .buttonStyle(PressScaleButtonStyle())
    }
}
