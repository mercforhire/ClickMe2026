//
//  CancellationPoliciesView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Cancellation Policy View

struct CancellationPoliciesView: View {
    var body: some View {
        ZStack {
            CancellationPoliciesBrand.bg.ignoresSafeArea()
            CancellationPoliciesBlobLayer().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    CancellationDeadlinesCard()
                    RefundEligibilityCard()
                    HowToInitiateCard()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Cancellation Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(CancellationPoliciesBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Previews

#Preview("Cancellation Policy") {
    NavigationStack {
        CancellationPoliciesView()
    }
    .preferredColorScheme(.dark)
}
