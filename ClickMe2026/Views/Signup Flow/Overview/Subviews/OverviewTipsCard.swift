//
//  OverviewTipsCard.swift
//  ClickMe2026
//

import SwiftUI

/// Card containing the "Tips for a Great Profile" header and a list of expandable tips.
struct OverviewTipsCard: View {
    let tips: [ProfileTip]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 20))
                    .foregroundColor(OverviewTheme.green)
                Text("Tips for a Great Profile")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(OverviewTheme.textPrimary)
            }
            .padding(.bottom, 18)

            ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                OverviewTipRow(tip: tip)
                if index < tips.count - 1 {
                    Divider().overlay(Color.white.opacity(0.07))
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(OverviewTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(OverviewTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}
