//
//  ClientProfileHomeListItem.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// A single tappable row inside a section — icon badge, title, trailing
/// chevron. `isDestructive` swaps the palette to error red for actions like
/// Log Out.
struct ClientProfileHomeListItem: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                iconBadge

                Text(title)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(isDestructive
                                     ? ClientProfileHomeBrand.error
                                     : ClientProfileHomeBrand.onSurface)

                Spacer()

                Image(systemName: isDestructive ? "rectangle.portrait.and.arrow.right" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isDestructive
                                     ? ClientProfileHomeBrand.error.opacity(0.40)
                                     : ClientProfileHomeBrand.onSurfaceVar)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ClientProfileHomeBrand.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isDestructive
                                    ? ClientProfileHomeBrand.error.opacity(0.20)
                                    : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDestructive ? ClientProfileHomeBrand.errorBg : ClientProfileHomeBrand.iconBg)
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(isDestructive
                                 ? ClientProfileHomeBrand.error
                                 : ClientProfileHomeBrand.primary)
                .shadow(color: isDestructive ? .clear : ClientProfileHomeBrand.primary.opacity(0.40), radius: 6)
        }
    }
}
