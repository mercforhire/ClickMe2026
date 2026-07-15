//
//  PreviewNavHarness.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

#if DEBUG

import SwiftUI

/// Wraps a preview target inside a `NavigationStack` with a fake parent row
/// already pushed onto the path, so the system back chevron renders in the
/// canvas — the closest we can get to "this screen at runtime, mid-flow"
/// without spinning up the whole app.
///
/// Replaces the per-screen `<Feature>PreviewHarness` struct + matching
/// `<Feature>PreviewRoute` enum boilerplate that used to live at the bottom
/// of every view file. Multi-variant previews now pick their variant by
/// constructing the view differently in each `#Preview` block, not by
/// switching on a route.
///
/// Usage:
/// ```
/// #Preview("Default") {
///     PreviewNavHarness(
///         parentText: "Account",
///         navTitle: "Settings",
///         rowTitle: "Send feedback"
///     ) {
///         FeedbackView()
///     }
///     .preferredColorScheme(.dark)
/// }
/// ```
struct PreviewNavHarness<Content: View>: View {

    let parentText: String
    let navTitle: String
    let rowTitle: String
    @ViewBuilder let content: () -> Content

    @State private var path: [PreviewRoute] = [.destination]

    private enum PreviewRoute: Hashable { case destination }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text(parentText)
                NavigationLink(rowTitle, value: PreviewRoute.destination)
            }
            .navigationTitle(navTitle)
            .navigationDestination(for: PreviewRoute.self) { _ in
                content()
            }
        }
    }
}

#endif
