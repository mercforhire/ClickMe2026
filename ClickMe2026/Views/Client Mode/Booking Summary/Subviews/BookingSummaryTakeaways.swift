//
//  BookingSummaryTakeaways.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Key takeaways section

struct BookingSummaryTakeaways: View {
    let takeaways: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BookingSummarySectionHeader(icon: "lightbulb", label: "KEY TAKEAWAYS")

            VStack(alignment: .leading, spacing: 12) {
                ForEach(takeaways, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(BookingSummaryBrand.brandGreen)
                            .padding(.top, 1)
                        Text(item)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(BookingSummaryBrand.onSurface)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(BookingSummaryGlassCardBackground())
        }
    }
}
