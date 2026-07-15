//
//  UpcomingBookingView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Booking Details View

struct UpcomingBookingView: View {

    @StateObject private var viewModel: UpcomingBookingViewModel

    var onJoinCall: () -> Void
    var onReschedule: () -> Void
    var onCancel: () -> Void
    var onCopyLink: () -> Void
    var onDownload: () -> Void

    // MARK: Init

    init(
        viewModel: UpcomingBookingViewModel = UpcomingBookingViewModel(),
        onJoinCall: @escaping () -> Void = {},
        onReschedule: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        onCopyLink: @escaping () -> Void = {},
        onDownload: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onJoinCall = onJoinCall
        self.onReschedule = onReschedule
        self.onCancel = onCancel
        self.onCopyLink = onCopyLink
        self.onDownload = onDownload
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass individual content fields keep compiling.
    init(
        bookingID: String = "#CM-98231",
        expertName: String = "Sarah Chen",
        expertTitle: String = "Senior UX Architect",
        expertImageURL: String = UpcomingBookingViewModel.sampleImageURL,
        expertRating: Double = 4.9,
        reviewCount: Int = 128,
        topic: String = "Advanced Product Strategy Review",
        consultationFee: String = "$150 / session",
        date: String = "Oct 15, 2024",
        timeRange: String = "10:00 AM - 11:00 AM",
        joinLink: String = "skype.com/j/clickme-sarah",
        preparationNote: String = "Please have your current product roadmap and user persona documents ready. We'll be diving deep into the Q4 objectives and identifying key friction points in the user journey.",
        attachmentName: String? = "Current_Strategy_V2.pdf",
        onJoinCall: @escaping () -> Void = {},
        onReschedule: @escaping () -> Void = {},
        onCancel: @escaping () -> Void = {},
        onCopyLink: @escaping () -> Void = {},
        onDownload: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: UpcomingBookingViewModel(
                bookingID: bookingID,
                expertName: expertName,
                expertTitle: expertTitle,
                expertImageURL: expertImageURL,
                expertRating: expertRating,
                reviewCount: reviewCount,
                topic: topic,
                consultationFee: consultationFee,
                date: date,
                timeRange: timeRange,
                joinLink: joinLink,
                preparationNote: preparationNote,
                attachmentName: attachmentName
            ),
            onJoinCall: onJoinCall,
            onReschedule: onReschedule,
            onCancel: onCancel,
            onCopyLink: onCopyLink,
            onDownload: onDownload
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            UpcomingBookingBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    UpcomingBookingStatusRow(bookingID: viewModel.bookingID)

                    UpcomingBookingExpertCard(
                        expertName: viewModel.expertName,
                        expertTitle: viewModel.expertTitle,
                        expertImageURL: viewModel.expertImageURL,
                        expertRating: viewModel.expertRating,
                        reviewCount: viewModel.reviewCount
                    )

                    UpcomingBookingTopicCard(
                        topic: viewModel.topic,
                        consultationFee: viewModel.consultationFee
                    )

                    UpcomingBookingDateTimeRow(
                        date: viewModel.date,
                        timeRange: viewModel.timeRange
                    )

                    UpcomingBookingJoinCard(
                        joinLink: viewModel.joinLink,
                        onJoinCall: onJoinCall,
                        onCopyLink: onCopyLink
                    )

                    UpcomingBookingPrepNotesCard(
                        preparationNote: viewModel.preparationNote,
                        attachmentName: viewModel.attachmentName,
                        onDownload: onDownload
                    )

                    UpcomingBookingSecondaryActions(
                        onReschedule: onReschedule,
                        onCancel: onCancel
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Upcoming Booking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(UpcomingBookingBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Preview harness

private enum UpcomingBookingPreviewRoute: Hashable {
    case confirmed
    case noAttachment
}

/// Wraps the booking-details screen inside a NavigationStack with a dummy
/// "My Bookings" parent already pushed, so the system back chevron renders
/// in the canvas.
private struct UpcomingBookingPreviewHarness: View {
    let route: UpcomingBookingPreviewRoute
    @State private var path: [UpcomingBookingPreviewRoute]

    init(route: UpcomingBookingPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Upcoming sessions")
                NavigationLink("Booking details", value: route)
            }
            .navigationTitle("My Bookings")
            .navigationDestination(for: UpcomingBookingPreviewRoute.self) { dest in
                switch dest {
                case .confirmed:
                    UpcomingBookingView()
                case .noAttachment:
                    UpcomingBookingView(attachmentName: nil)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Booking Details — Confirmed") {
    UpcomingBookingPreviewHarness(route: .confirmed)
        .preferredColorScheme(.dark)
}

#Preview("No Attachment") {
    UpcomingBookingPreviewHarness(route: .noAttachment)
        .preferredColorScheme(.dark)
}
