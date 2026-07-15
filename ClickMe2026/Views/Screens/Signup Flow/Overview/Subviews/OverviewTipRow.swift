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
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Brand.onSurface)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Brand.onSurfaceMuted)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.vertical, 16)
            }
            .buttonStyle(.plain)

            if expanded {
                Text(tip.detail)
                    .font(.system(size: 15))
                    .foregroundColor(Brand.onSurfaceMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
            }
        }
    }
}
