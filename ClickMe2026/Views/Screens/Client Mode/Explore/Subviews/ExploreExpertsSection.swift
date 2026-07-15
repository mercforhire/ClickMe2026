//
//  ExploreExpertsSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExploreExpertsSection: View {
    let experts: [Expert]
    var onSeeAll: () -> Void = {}
    var onViewProfile: (Expert) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Experts")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button("See all", action: onSeeAll)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(ExploreBrand.brandGreen)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                ForEach(experts) { expert in
                    ExpertCard(
                        expert: expert,
                        onViewProfile: { onViewProfile(expert) }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
