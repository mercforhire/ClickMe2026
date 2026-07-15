//
//  OverviewHeader.swift
//  ClickMe2026
//

import SwiftUI

struct OverviewHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("ClickMe")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(OverviewTheme.textPrimary)
                .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Complete Your Profile!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(OverviewTheme.textPrimary)

                Text("A complete profile helps you get more bookings.")
                    .font(.system(size: 16))
                    .foregroundColor(OverviewTheme.textSecond)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 16)
        }
    }
}
