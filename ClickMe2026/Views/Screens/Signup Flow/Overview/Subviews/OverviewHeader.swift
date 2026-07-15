//
//  OverviewHeader.swift
//  ClickMe2026
//

import SwiftUI

struct OverviewHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Complete Your Profile!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Brand.onSurface)

                Text("A complete profile helps you get more bookings.")
                    .font(.system(size: 16))
                    .foregroundColor(Brand.onSurfaceMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
        }
    }
}
