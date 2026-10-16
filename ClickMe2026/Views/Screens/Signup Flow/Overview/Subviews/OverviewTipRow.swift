//
//  OverviewTipRow.swift
//  ClickMe2026
//

import SwiftUI

/// Expandable tip row inside the "Tips for a Great Profile" card.
struct OverviewTipRow: View {
    let tip: ProfileTip
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { expanded.toggle() }
            } label: {
                HStack {
                    Text(tip.title)
                        .font(.body.weight(.semibold))
                        .foregroundColor(Brand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Brand.onSurfaceMuted)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(tip.detail)
                    .font(.subheadline)
                    .foregroundColor(Brand.onSurfaceMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
            }
        }
    }
}
