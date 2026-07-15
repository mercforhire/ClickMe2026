//
//  MyBookingsSegmentPicker.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Upcoming / Past segment picker

struct MyBookingsSegmentPicker: View {
    @Binding var selectedTab: Int

    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(MyBookingsBrand.tabBg)
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
                    .font(.system(size: 15, weight: isActive ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isActive ? MyBookingsBrand.onSurface : MyBookingsBrand.onSurfaceVar)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)

                if isActive {
                    Capsule()
                        .fill(MyBookingsBrand.brandGreen)
                        .frame(height: 3)
                        .shadow(color: MyBookingsBrand.brandGreen.opacity(0.60), radius: 5)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
