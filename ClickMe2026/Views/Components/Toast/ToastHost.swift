//
//  ToastHost.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Renders `ToastCenter.shared.current` as a bottom-anchored chip above the
/// tab bar (UI-SPEC section 10). Applied once, beside `CallOverlayHost`, on
/// the client shell.
///
/// The fade is the only motion, so Reduce Motion needs no separate branch.
struct ToastHost: ViewModifier {
    private let center = ToastCenter.shared

    /// Standard tab bar height; the overlay sits above the safe area, not above the tab bar.
    private let tabBarHeight: CGFloat = 49

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                ZStack {
                    if let toast = center.current {
                        chip(for: toast)
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: center.current?.id)
            }
    }

    private func chip(for toast: ToastCenter.Toast) -> some View {
        HStack(spacing: 4) {
            if let systemImage = toast.systemImage {
                Image(systemName: systemImage)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.primary)
            }
            Text(toast.message)
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Brand.surfaceContainerHigh)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Brand.primary.opacity(0.6), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 24 + tabBarHeight)
        .contentShape(Rectangle())
        .onTapGesture { center.dismiss() }
        .accessibilityAddTraits(.isStaticText)
    }
}

#Preview("Toast") {
    Color.black
        .ignoresSafeArea()
        .modifier(ToastHost())
        .onAppear { ToastCenter.shared.show("Reschedule accepted", systemImage: "checkmark.circle.fill") }
}
