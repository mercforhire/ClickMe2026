//
//  ClientProfileHomeModeSwitchCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Prominent call-to-action row on `ClientProfileHomeScreen` that navigates
/// to `ModeSwitchView`. Sized and coloured to draw attention — this is the
/// primary way clients discover the expert-side flow.
struct ClientProfileHomeModeSwitchCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge

                VStack(alignment: .leading, spacing: 3) {
                    Text("Switch to Expert Mode")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(ClientProfileHomeBrand.onSurface)
                    Text("Start offering consultations")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(ClientProfileHomeBrand.onSurfaceVar)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ClientProfileHomeBrand.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ClientProfileHomeBrand.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(ClientProfileHomeBrand.primary.opacity(0.55), lineWidth: 1.2)
                    )
                    .shadow(color: ClientProfileHomeBrand.primary.opacity(0.20), radius: 12, x: 0, y: 3)
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ClientProfileHomeBrand.primary.opacity(0.16))
                .frame(width: 44, height: 44)
            Image(systemName: "briefcase.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ClientProfileHomeBrand.primary)
        }
    }
}
