//
//  ExploreHeroHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

struct ExploreHeroHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Find your next expert")
                .font(.brand(.title, weight: .bold))
                .foregroundColor(.white)

            Text("Connect with the top 1% of industry leaders.")
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Color.white.opacity(0.50))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
