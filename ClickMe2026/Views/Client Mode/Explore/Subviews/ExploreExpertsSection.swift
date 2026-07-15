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
    var onMore: () -> Void = {}
    var onViewProfile: (Expert) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recommended Experts")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onMore) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
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
