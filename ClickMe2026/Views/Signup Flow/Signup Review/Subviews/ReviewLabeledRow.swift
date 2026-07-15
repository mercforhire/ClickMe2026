//
//  ReviewLabeledRow.swift
//  ClickMe2026
//

import SwiftUI

/// "Label: Value" pair — grey label, white bold value.
struct ReviewLabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(label):")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(ReviewTheme.textSecond)
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(ReviewTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
