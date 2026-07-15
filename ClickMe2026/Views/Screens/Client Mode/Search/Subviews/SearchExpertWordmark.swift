//
//  SearchExpertWordmark.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "ClickMe" cursor-C wordmark

struct SearchExpertWordmark: View {
    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                Text("C")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(SearchExpertBrand.onSurface)
                Image(systemName: "cursorarrow")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(SearchExpertBrand.onSurface)
                    .offset(x: 1, y: -1)
            }
            Text("lickMe")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(SearchExpertBrand.onSurface)
        }
    }
}
