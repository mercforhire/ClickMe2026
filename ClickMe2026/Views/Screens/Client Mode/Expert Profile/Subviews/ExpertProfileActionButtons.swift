//
//  ExpertProfileActionButtons.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Book Session + Message buttons

struct ExpertProfileActionButtons: View {
    let onBookSession: () -> Void
    let onMessage: () -> Void
    /// When false, the Book Session CTA is swapped for a disabled
    /// "Not accepting bookings" state — the expert hasn't finished
    /// Stripe Connect verification, so a booking attempt would 422 on
    /// the server. Backend field `is_bookable` on
    /// `/experts/:id/details` seeds this.
    var isBookable: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            bookSessionButton
            messageButton
        }
    }

    @ViewBuilder
    private var bookSessionButton: some View {
        if isBookable {
            Button(action: onBookSession) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.body.weight(.medium))
                    Text("Book Session")
                        .font(.brand(.callout, weight: .bold))
                }
                .foregroundColor(ExpertProfileBrand.onPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(ExpertProfileBrand.brandGreen)
                        .shadow(color: ExpertProfileBrand.brandGreen.opacity(0.40), radius: 14, x: 0, y: 4)
                )
            }
            .buttonStyle(ProfileActionStyle())
        } else {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.body.weight(.medium))
                Text("Not accepting bookings")
                    .font(.brand(.callout, weight: .bold))
            }
            .foregroundColor(ExpertProfileBrand.onPrimary.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ExpertProfileBrand.brandGreen.opacity(0.35))
            )
        }
    }

    private var messageButton: some View {
        Button(action: onMessage) {
            HStack(spacing: 8) {
                Image(systemName: "bubble.left")
                    .font(.body.weight(.medium))
                Text("Message")
                    .font(.brand(.callout, weight: .bold))
            }
            .foregroundColor(ExpertProfileBrand.brandGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ExpertProfileBrand.brandGreen, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(ProfileActionStyle())
    }
}
