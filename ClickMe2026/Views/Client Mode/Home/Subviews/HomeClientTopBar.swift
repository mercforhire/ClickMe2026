//
//  HomeClientTopBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Top app bar — centered ClickMe brand

struct HomeClientTopBar: View {
    var body: some View {
        HStack(spacing: 10) {
            ClickMeLogoMark(size: 28)
            Text("ClickMe")
                .font(.system(size: 20, weight: .semibold))
                .tracking(-0.2)
                .foregroundColor(HomeClientBrand.onSurface)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            HomeClientBrand.surfaceContainer
                .overlay(
                    Rectangle()
                        .fill(HomeClientBrand.outlineVariant)
                        .frame(height: 1),
                    alignment: .bottom
                )
                .ignoresSafeArea(edges: .top)
        )
    }
}
