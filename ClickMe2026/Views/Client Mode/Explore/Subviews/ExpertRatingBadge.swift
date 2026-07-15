//
//  ExpertRatingBadge.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertRatingBadge: View {
    let rating: Double

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 10, weight: .bold))
            Text(String(format: "%.1f", rating))
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color(red: 0.10, green: 0.28, blue: 0.16).opacity(0.92))
                .overlay(
                    Capsule()
                        .stroke(ExploreBrand.brandGreen.opacity(0.50), lineWidth: 1)
                )
        )
    }
}
