//
//  BookingSummaryActions.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Action buttons — Book Again + Message Expert

struct BookingSummaryActions: View {
    let onBookAgain: () -> Void
    let onMessageExpert: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            bookAgainButton
            messageExpertButton
        }
    }

    private var bookAgainButton: some View {
        Button(action: onBookAgain) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle")
                    .font(.title3.weight(.regular))
                Text("Book Again")
                    .font(.brand(.callout, weight: .bold))
            }
            .foregroundColor(BookingSummaryBrand.onPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(BookingSummaryBrand.brandGreen)
                    .shadow(color: BookingSummaryBrand.brandGreen.opacity(0.45), radius: 18, x: 0, y: 5)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var messageExpertButton: some View {
        Button(action: onMessageExpert) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .font(.title3.weight(.regular))
                Text("Message Expert")
                    .font(.brand(.callout, weight: .bold))
            }
            .foregroundColor(BookingSummaryBrand.brandGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(BookingSummaryBrand.brandGreen.opacity(0.50), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }
}
