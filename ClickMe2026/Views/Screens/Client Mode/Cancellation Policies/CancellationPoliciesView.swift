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
            GreenGlowBlobLayer().ignoresSafeArea()

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

// MARK: - Preview harness

private enum CancellationPoliciesPreviewRoute: Hashable {
    case policy
}

/// Wraps the cancellation-policy screen inside a NavigationStack with a
/// dummy "Cancellation" parent already pushed, so the system back chevron
/// renders in the canvas.
private struct CancellationPoliciesPreviewHarness: View {
    let route: CancellationPoliciesPreviewRoute
    @State private var path: [CancellationPoliciesPreviewRoute]

    init(route: CancellationPoliciesPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Help")
                NavigationLink("Cancellation policy", value: route)
            }
            .navigationTitle("Cancellation")
            .navigationDestination(for: CancellationPoliciesPreviewRoute.self) { _ in
                CancellationPoliciesView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Cancellation Policy") {
    CancellationPoliciesPreviewHarness(route: .policy)
        .preferredColorScheme(.dark)
}
