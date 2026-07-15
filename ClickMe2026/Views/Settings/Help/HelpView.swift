//
//  HelpView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Help View

struct HelpView: View {

    @State private var searchText: String = ""
    @State private var expandedFAQ: HelpFAQCategory?
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack {
            HelpBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    HelpSearchBar(text: $searchText, isFocused: $searchFocused)

                    faqSection

                    contactSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(HelpBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - FAQ section

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader("Frequently Asked Questions")

            VStack(spacing: 12) {
                ForEach(HelpFAQCategory.allCases) { category in
                    HelpFAQCard(
                        category: category,
                        isExpanded: expandedFAQ == category,
                        onTap: { toggle(category) }
                    )
                }
            }
        }
    }

    private func toggle(_ category: HelpFAQCategory) {
        withAnimation(.easeInOut(duration: 0.2)) {
            expandedFAQ = (expandedFAQ == category) ? nil : category
        }
    }

    // MARK: - Contact section

    private var contactSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HelpSectionHeader("Contact Us")

            VStack(spacing: 12) {
                HelpContactRow(
                    icon: "envelope",
                    title: "Email Us",
                    action: {}
                )
                HelpContactRow(
                    icon: "bubble.left.and.bubble.right",
                    title: "Live Chat",
                    action: {}
                )
            }
        }
    }
}

// MARK: - Preview harness

private enum HelpPreviewRoute: Hashable {
    case help
}

/// Wraps the help screen inside a NavigationStack with a dummy
/// "Settings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct HelpPreviewHarness: View {
    let route: HelpPreviewRoute
    @State private var path: [HelpPreviewRoute]

    init(route: HelpPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Support")
                NavigationLink("Help", value: route)
            }
            .navigationTitle("Settings")
            .navigationDestination(for: HelpPreviewRoute.self) { _ in
                HelpView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Help") {
    HelpPreviewHarness(route: .help)
        .preferredColorScheme(.dark)
}
