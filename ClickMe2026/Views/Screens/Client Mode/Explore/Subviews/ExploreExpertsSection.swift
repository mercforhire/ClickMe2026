//
//  ExploreExpertsSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct ExploreExpertsSection: View {
    let experts: [Expert]
    var onSeeAll: () -> Void = {}
    var onTapExpert: (Expert) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Experts")
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(.brand(.caption, weight: .medium))
                    .foregroundColor(ExploreBrand.brandGreen)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(experts) { expert in
                    ExpertCard(
                        expert: expert,
                        onTap: { onTapExpert(expert) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
