//
//  HomeExpertTabBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Bottom tab bar

struct HomeExpertTabBar: View {
    @Binding var selection: HomeExpertTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(HomeExpertTab.allCases, id: \.self) { tab in
                HomeExpertTabItem(
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
            HomeExpertBrand.surfaceContainer
                .overlay(
                    Rectangle()
                        .fill(HomeExpertBrand.outlineVariant)
                        .frame(height: 1),
                    alignment: .top
                )
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
