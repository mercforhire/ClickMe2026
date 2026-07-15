//
//  RequestDecisionEarningsSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionEarningsSection: View {
    let potentialEarnings: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Earnings")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurface)

            HStack {
                Text("Potential Earnings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(RequestDecisionTheme.brandGreen)
                Spacer()
                Text(String(format: "$%.2f", potentialEarnings))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(RequestDecisionTheme.brandGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RequestDecisionTheme.earningsBg)
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(RequestDecisionTheme.brandGreen.opacity(0.25), lineWidth: 1))
            )
        }
    }
}
