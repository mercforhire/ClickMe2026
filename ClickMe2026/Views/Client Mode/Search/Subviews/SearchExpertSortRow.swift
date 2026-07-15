//
//  SearchExpertSortRow.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "Sort by" row with current selection + chevron

struct SearchExpertSortRow: View {
    let sortOption: String
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text("Sort by")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurface)
            Spacer()
            Button(action: onTap) {
                HStack(spacing: 4) {
                    Text(sortOption)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SearchExpertBrand.onSurfaceVar)
                }
            }
            .buttonStyle(.plain)
        }
    }
}
