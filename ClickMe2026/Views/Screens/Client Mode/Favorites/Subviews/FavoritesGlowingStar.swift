//
//  FavoritesGlowingStar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Multi-layer glowing star illustration

struct FavoritesGlowingStar: View {
    var body: some View {
        ZStack {
            Image(systemName: "star")
                .font(.system(size: 130, weight: .ultraLight))
                .foregroundColor(FavoritesBrand.brandGreen.opacity(0.18))
                .blur(radius: 20)

            Image(systemName: "star")
                .font(.system(size: 110, weight: .ultraLight))
                .foregroundColor(FavoritesBrand.brandGreen.opacity(0.30))
                .blur(radius: 8)

            Image(systemName: "star")
                .font(.system(size: 100, weight: .thin))
                .foregroundColor(FavoritesBrand.brandGreen.opacity(0.55))
                .blur(radius: 3)

            Image(systemName: "star")
                .font(.system(size: 90, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [FavoritesBrand.brandGreen, FavoritesBrand.brandGreenAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: FavoritesBrand.brandGreen.opacity(0.80), radius: 16)

            ForEach([
                (CGFloat(-70), CGFloat(-40), CGFloat(4)),
                (CGFloat(80), CGFloat(-30), CGFloat(5)),
                (CGFloat(-80), CGFloat(40), CGFloat(3)),
                (CGFloat(65), CGFloat(55), CGFloat(4)),
                (CGFloat(0), CGFloat(-85), CGFloat(3)),
            ], id: \.0) { dx, dy, r in
                Circle()
                    .fill(FavoritesBrand.brandGreen.opacity(0.55))
                    .frame(width: r * 2, height: r * 2)
                    .offset(x: dx, y: dy)
            }
        }
        .frame(width: 200, height: 200)
    }
}
