//
//  OverviewProgressBar.swift
//  ClickMe2026
//

import SwiftUI

/// "Profile Completion" label, percentage, and animated capsule fill.
struct OverviewProgressBar: View {
    /// Actual completion ratio (0...1) used for the percentage label.
    let progress: Double
    /// Animated width ratio (0...1) used for the visual fill.
    let animatedProgress: Double

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Profile Completion")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(OverviewTheme.textPrimary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(OverviewTheme.textPrimary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(OverviewTheme.track)
                    Capsule()
                        .fill(OverviewTheme.green)
                        .frame(width: geo.size.width * animatedProgress)
                        .shadow(color: OverviewTheme.green.opacity(0.75), radius: 9)
                }
            }
            .frame(height: 12)
        }
    }
}
