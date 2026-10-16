//
//  ExploreCategoriesSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct ExploreCategoriesSection: View {
    let categories: [ExpertCategory]
    let onSelect: (Int) -> Void
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Trending Categories")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("View all", action: onViewAll)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(ExploreBrand.brandGreen)
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories.indices, id: \.self) { i in
                        ExploreCategoryCard(
                            category: categories[i],
                            action: { onSelect(i) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
        }
    }
}
