//
//  WriteReviewView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Leave Review View

struct WriteReviewView: View {
    let expertName: String
    let expertImageURL: String
    var onSubmit: (Int, String, Bool) -> Void

    @StateObject private var viewModel: WriteReviewViewModel

    // MARK: Init

    init(
        expertName: String = "Dr. Anya Sharma",
        expertImageURL: String = "https://randomuser.me/api/portraits/women/55.jpg",
        viewModel: WriteReviewViewModel = WriteReviewViewModel(),
        onSubmit: @escaping (Int, String, Bool) -> Void = { _, _, _ in }
    ) {
        self.expertName = expertName
        self.expertImageURL = expertImageURL
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSubmit = onSubmit
    }

    // MARK: Body

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [WriteReviewBrand.topTint, WriteReviewBrand.bg],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.55)
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        WriteReviewExpertAvatar(
                            imageURL: expertImageURL,
                            glowPulse: viewModel.glowPulse
                        )
                        .padding(.bottom, 28)

                        WriteReviewHeadline(expertName: expertName)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 32)

                        WriteReviewStarRating(
                            selectedStars: viewModel.selectedStars,
                            hoverStar: viewModel.hoverStar,
                            starsAnimated: viewModel.starsAnimated,
                            onSelect: { viewModel.selectStar($0) }
                        )
                        .padding(.bottom, 28)

                        WriteReviewTextField(text: $viewModel.reviewText)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)

                        WriteReviewAnonymousToggle(isAnonymous: $viewModel.isAnonymous)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                    }
                }

                WriteReviewSubmitButton(
                    isSubmitting: viewModel.isSubmitting,
                    didSubmit: viewModel.didSubmit,
                    action: { viewModel.submit(onSubmit: onSubmit) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            viewModel.glowPulse = true
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.25)) {
                viewModel.starsAnimated = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Default — 5 stars") {
    WriteReviewView()
        .preferredColorScheme(.dark)
}

#Preview("3-star partial review") {
    WriteReviewView(
        viewModel: WriteReviewViewModel(
            selectedStars: 3,
            reviewText: "Helpful session overall, though I wish we covered a couple of topics in more depth."
        )
    )
    .preferredColorScheme(.dark)
}

#Preview("Submitted state") {
    WriteReviewView(
        viewModel: WriteReviewViewModel(
            selectedStars: 5,
            reviewText: "Outstanding consultation — I left with a clear action plan.",
            didSubmit: true,
            starsAnimated: true
        )
    )
    .preferredColorScheme(.dark)
}
