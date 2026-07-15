//
//  FavoritesEmptyState.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Empty state — illustration + headline + actions + pro tip

struct FavoritesEmptyState: View {
    let onExplore: () -> Void
    let onViewHistory: () -> Void

    var body: some View {
        ZStack {
            GreenGlowBlobLayer()

            VStack(spacing: 0) {
                Spacer()

                FavoritesGlowingStar()
                    .padding(.bottom, 32)

                VStack(spacing: 12) {
                    Text("No favorites yet")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(FavoritesBrand.onSurface)

                    Text("Start exploring and save your favorite experts\nto find them easily later.")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(FavoritesBrand.onSurfaceVar)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 36)

                VStack(spacing: 14) {
                    Button(action: onExplore) {
                        Text("Explore Experts")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(FavoritesBrand.onPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(FavoritesBrand.brandGreen)
                                    .shadow(color: FavoritesBrand.brandGreen.opacity(0.55), radius: 20, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    Button(action: onViewHistory) {
                        Text("View My History")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(FavoritesBrand.onSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.13, green: 0.14, blue: 0.15))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                            )
                    }
                    .buttonStyle(PressScaleButtonStyle())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)

                FavoritesProTipCard()
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}
