//
//  OverviewNextBar.swift
//  ClickMe2026
//

import SwiftUI

/// Bottom-pinned "Next" CTA bar.
struct OverviewNextBar: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Next")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Brand.surface)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Capsule().fill(Brand.primary))
                .shadow(color: Brand.primary.opacity(0.4), radius: 14, y: 4)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(Brand.surface)
    }
}
