//
//  UpcomingBookingsSegmentPicker.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Upcoming / Past segment picker

/// Expert counterpart to `MyBookingsSegmentPicker` — same shape and
/// interaction, retuned to the expert brand tokens (Brand.* instead of
/// the client-specific `MyBookingsBrand.*`).
struct UpcomingBookingsSegmentPicker: View {
    @Binding var selectedTab: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Brand.surfaceContainer)
                .frame(height: 48)

            HStack(spacing: 0) {
                tab("Upcoming", index: 0)
                tab("Past", index: 1)
            }
        }
        .frame(height: 48)
    }

    private func tab(_ label: String, index: Int) -> some View {
        let isActive = selectedTab == index
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = index
            }
        } label: {
            ZStack(alignment: .bottom) {
                Text(label)
                    .font(.system(.subheadline, design: .rounded).weight(isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? Brand.onSurface : Brand.onSurfaceVariant)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)

                if isActive {
                    Capsule()
                        .fill(Brand.primary)
                        .frame(height: 3)
                        .shadow(color: Brand.primary.opacity(0.60), radius: 5)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
