//
//  BookingRequestSentView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking Request Sent View

struct BookingRequestSentView: View {
    @StateObject private var viewModel: BookingRequestSentViewModel

    var onViewBookings: () -> Void
    var onBackToHome: () -> Void

    // MARK: Init

    init(
        viewModel: BookingRequestSentViewModel = BookingRequestSentViewModel(),
        onViewBookings: @escaping () -> Void = {},
        onBackToHome: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onViewBookings = onViewBookings
        self.onBackToHome = onBackToHome
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        expertName: String = "Sarah Jenkins",
        topic: String = "Advanced UI Architecture",
        dateTime: String = "Oct 24, 2023 | 2:00 PM - 3:00 PM",
        onViewBookings: @escaping () -> Void = {},
        onBackToHome: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: BookingRequestSentViewModel(
                expertName: expertName,
                topic: topic,
                dateTime: dateTime
            ),
            onViewBookings: onViewBookings,
            onBackToHome: onBackToHome
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BookingRequestSentBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 32)

                    BookingRequestSentCheckIcon(
                        scale: viewModel.iconScale,
                        opacity: viewModel.iconOpacity,
                        glowPulse: viewModel.glowPulse
                    )
                    .padding(.bottom, 28)

                    BookingRequestSentHeadline(
                        expertName: viewModel.expertName,
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset
                    )
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)

                    BookingRequestSentDetailsCard(
                        topic: viewModel.topic,
                        dateTime: viewModel.dateTime,
                        opacity: viewModel.cardOpacity,
                        yOffset: viewModel.cardOffset
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    BookingRequestSentActions(
                        onViewBookings: onViewBookings,
                        onBackToHome: onBackToHome,
                        opacity: viewModel.btnsOpacity,
                        yOffset: viewModel.btnsOffset
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { viewModel.runEntryAnimation() }
    }
}

// MARK: - Preview harness

private enum BookingRequestSentPreviewRoute: Hashable {
    case `default`
    case custom
}

/// Wraps the request-sent screen inside a NavigationStack with a dummy
/// "Book a session" parent already pushed, so the system back chevron
/// renders in the canvas.
private struct BookingRequestSentPreviewHarness: View {
    let route: BookingRequestSentPreviewRoute
    @State private var path: [BookingRequestSentPreviewRoute]

    init(route: BookingRequestSentPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Confirm booking")
                NavigationLink("Request sent", value: route)
            }
            .navigationTitle("Book a session")
            .navigationDestination(for: BookingRequestSentPreviewRoute.self) { dest in
                switch dest {
                case .default:
                    BookingRequestSentView()
                case .custom:
                    BookingRequestSentView(
                        expertName: "Dr. Marcus Chen",
                        topic: "Growth Strategy Session",
                        dateTime: "Nov 5, 2024 | 10:00 AM - 11:00 AM"
                    )
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Booking Request Sent") {
    BookingRequestSentPreviewHarness(route: .default)
        .preferredColorScheme(.dark)
}

#Preview("Custom Expert") {
    BookingRequestSentPreviewHarness(route: .custom)
        .preferredColorScheme(.dark)
}
