//
//  ExpertCancellationMainCard.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Main glass card: warning icon + headline + client box + reason picker + refund note

struct ExpertCancellationMainCard: View {
    let clientName: String
    let clientImageURL: String
    let sessionTopic: String
    let dateTime: String
    let refundType: String
    let selectedReason: CancellationReason
    let onTapReasonPicker: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            warningIcon
            headline

            ExpertCancellationClientBox(
                clientName: clientName,
                clientImageURL: clientImageURL,
                sessionTopic: sessionTopic,
                dateTime: dateTime,
                refundType: refundType
            )

            reasonSelector

            Text("Refunds typically appear in the client's account within 3–5 business days.")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(ExpertCancellationBrand.onSurfaceVar.opacity(0.60))
                .italic()
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ExpertCancellationBrand.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(ExpertCancellationBrand.cardBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Warning icon

    private var warningIcon: some View {
        ZStack {
            Circle()
                .fill(ExpertCancellationBrand.iconCircle)
                .overlay(Circle().stroke(ExpertCancellationBrand.iconBorder, lineWidth: 1))
                .frame(width: 66, height: 66)
                .shadow(color: ExpertCancellationBrand.brandGreen.opacity(0.15), radius: 10)
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 26, weight: .light))
                .foregroundColor(ExpertCancellationBrand.brandGreen)
        }
    }

    // MARK: Headline

    private var headline: some View {
        VStack(spacing: 10) {
            Text("Confirm Cancellation?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(ExpertCancellationBrand.onSurface)
                .multilineTextAlignment(.center)

            Text("Please review the booking details below before confirming. Canceling may affect your expert rating.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ExpertCancellationBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
    }

    // MARK: Reason selector

    private var reasonSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reason for Cancellation")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(ExpertCancellationBrand.onSurfaceVar)

            Button(action: onTapReasonPicker) {
                HStack {
                    Text(selectedReason.rawValue)
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(
                            selectedReason == .none
                                ? ExpertCancellationBrand.onSurfaceVar
                                : ExpertCancellationBrand.onSurface
                        )
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ExpertCancellationBrand.onSurfaceVar)
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(ExpertCancellationBrand.dropdownBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(ExpertCancellationBrand.innerBorder, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
}
