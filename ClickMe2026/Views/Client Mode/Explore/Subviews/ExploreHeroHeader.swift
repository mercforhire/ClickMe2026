//
//  ExploreHeroHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExploreHeroHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Find your next expert")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Connect with the top 1% of industry leaders.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.50))
        }
    }
}
