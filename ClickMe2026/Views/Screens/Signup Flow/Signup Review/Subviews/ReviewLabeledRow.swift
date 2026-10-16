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
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurfaceMuted)
            Text(value)
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
