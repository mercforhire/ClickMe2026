//
//  BookingSummaryView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-23.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Session Summary View

struct BookingSummaryView: View {

    @StateObject private var viewModel: BookingSummaryViewModel

    var onBookAgain: () -> Void
    var onMessageExpert: () -> Void
    var onCallRecording: () -> Void
    var onSharedNotes: () -> Void
    var onMoreOptions: () -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: Init

    init(
        viewModel: BookingSummaryViewModel = BookingSummaryViewModel(),
        onBookAgain: @escaping () -> Void = {},
        onMessageExpert: @escaping () -> Void = {},
        onCallRecording: @escaping () -> Void = {},
        onSharedNotes: @escaping () -> Void = {},
        onMoreOptions: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookAgain = onBookAgain
        self.onMessageExpert = onMessageExpert
        self.onCallRecording = onCallRecording
        self.onSharedNotes = onSharedNotes
        self.onMoreOptions = onMoreOptions
    }

    /// Convenience init mirroring the original signature so existing call sites
    /// that pass individual data fields keep compiling.
    init(
        expertName: String = "David Miller",
        expertTitle: String = "Machine Learning Lead",
        expertImageURL: String = "https://lh3.googleusercontent.com/aida-public/AB6AXuBnTZGMesjV2RDjvDlTqiAhGQcKvp9VwRAGKeFBQjZ2Ne3kX7qgo1NEGGhlYpLGEM-O7oYGv4ngC22GSYW5O_7nNSrkzsKF21q6DvxVUAClnY1puOrcVVRfxo7a2Q8VsPQTLluTXbfFumBJAsA8IdqCPigzs8DbXKLxdIp29xbIBxU61gPcbgR5RkgqIyJ0vmmgN_pFjG77f1XqxGlAMxxuvd1iOf-mQ1Wzc-mmg94vsBrnZYSiSZuYJ-83ZQi8i5encZyL6jSAENg",
        topic: String = "Machine Learning Consultation",
        dateTime: String = "Oct 8, 2024 • 2:00 PM - 3:00 PM",
        takeaways: [String] = BookingSummaryViewModel.sampleTakeaways,
        feedbackStars: Int = 5,
        feedbackText: String? = "David is truly an expert in his field. The way he broke down complex GAN concepts was incredible. Already seeing performance improvements in our dev environment. Highly recommended!",
        onBookAgain: @escaping () -> Void = {},
        onMessageExpert: @escaping () -> Void = {},
        onCallRecording: @escaping () -> Void = {},
        onSharedNotes: @escaping () -> Void = {},
        onMoreOptions: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: BookingSummaryViewModel(
                expertName: expertName,
                expertTitle: expertTitle,
                expertImageURL: expertImageURL,
                topic: topic,
                dateTime: dateTime,
                takeaways: takeaways,
                feedbackStars: feedbackStars,
                feedbackText: feedbackText
            ),
            onBookAgain: onBookAgain,
            onMessageExpert: onMessageExpert,
            onCallRecording: onCallRecording,
            onSharedNotes: onSharedNotes,
            onMoreOptions: onMoreOptions
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            BookingSummaryBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                BookingSummaryNavBar(
                    onBack: { dismiss() },
                    onMoreOptions: onMoreOptions
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        BookingSummaryExpertCard(
                            expertName: viewModel.expertName,
                            expertTitle: viewModel.expertTitle,
                            expertImageURL: viewModel.expertImageURL,
                            topic: viewModel.topic,
                            dateTime: viewModel.dateTime
                        )

                        BookingSummaryTakeaways(takeaways: viewModel.takeaways)

                        BookingSummaryFeedback(
                            feedbackStars: viewModel.feedbackStars,
                            feedbackText: viewModel.feedbackText
                        )

                        BookingSummaryResources(
                            onCallRecording: onCallRecording,
                            onSharedNotes: onSharedNotes
                        )

                        BookingSummaryActions(
                            onBookAgain: onBookAgain,
                            onMessageExpert: onMessageExpert
                        )
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 48)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Previews

#Preview("Session Summary — 5 Stars") {
    BookingSummaryView()
        .preferredColorScheme(.dark)
}

#Preview("Session Summary — No Feedback") {
    BookingSummaryView(
        feedbackStars: 0,
        feedbackText: nil
    )
    .preferredColorScheme(.dark)
}
