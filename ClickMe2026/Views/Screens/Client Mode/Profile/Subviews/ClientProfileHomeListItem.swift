//
//  ClientProfileHomeListItem.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// A single tappable row inside a section — icon badge, title, trailing
/// chevron. `isDestructive` swaps the palette to error red for actions like
/// Log Out. `isBusy` shows a spinner in place of the trailing icon and
/// disables the row while its action is still running (the Log out wait,
/// up to about 6 seconds while the push cleanup finishes), so the tap is
/// visibly acknowledged and cannot be repeated.
struct ClientProfileHomeListItem: View {
    let icon: String
    let title: String
    var isDestructive: Bool = false
    var isBusy: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                iconBadge

                Text(title)
                    .font(.callout.weight(.regular))
                    .foregroundColor(isDestructive
                                     ? ClientProfileHomeBrand.error
                                     : ClientProfileHomeBrand.onSurface)

                Spacer()

                if isBusy {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(
                            tint: isDestructive ? ClientProfileHomeBrand.error : ClientProfileHomeBrand.primary
                        ))
                        .accessibilityLabel("In progress")
                } else {
                    Image(systemName: isDestructive ? "rectangle.portrait.and.arrow.right" : "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isDestructive
                                         ? ClientProfileHomeBrand.error.opacity(0.40)
                                         : ClientProfileHomeBrand.onSurfaceVar)
                }
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
        .disabled(isBusy)
    }

    private var iconBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isDestructive ? ClientProfileHomeBrand.errorBg : ClientProfileHomeBrand.iconBg)
                .frame(width: 40, height: 40)
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundColor(isDestructive
                                 ? ClientProfileHomeBrand.error
                                 : ClientProfileHomeBrand.primary)
                .shadow(color: isDestructive ? .clear : ClientProfileHomeBrand.primary.opacity(0.40), radius: 6)
        }
    }
}
