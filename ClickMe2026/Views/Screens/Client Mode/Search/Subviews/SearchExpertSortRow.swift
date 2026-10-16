//
//  SearchExpertSortRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Sort by" row with current selection + chevron

struct SearchExpertSortRow: View {
    let sortOption: String
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text("Sort by")
                .font(.brand(.callout, weight: .bold))
                .foregroundColor(SearchExpertBrand.onSurface)
            Spacer()
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Text(sortOption)
                        .font(.brand(.subheadline, weight: .regular))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.medium))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
