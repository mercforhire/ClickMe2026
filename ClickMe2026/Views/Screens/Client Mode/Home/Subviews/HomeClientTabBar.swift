//
//  HomeClientTabBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Bottom tab bar

struct HomeClientTabBar: View {
    @Binding var selection: HomeClientTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeClientTab.allCases, id: \.self) { tab in
                HomeClientTabItem(
                    tab: tab,
                    isActive: selection == tab,
                    action: { selection = tab }
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            Brand.surfaceContainer
                .overlay(
                    Rectangle()
                        .fill(Brand.outlineVariant)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
