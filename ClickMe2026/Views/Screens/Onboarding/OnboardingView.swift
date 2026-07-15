//
//  OnboardingView.swift
//  ClickMe2026
//
//  Copyright © 2024 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let illustration: String // SF Symbol used as placeholder; swap for real assets
    let title: String
    let subtitle: String
}

// MARK: - Welcome / Onboarding Screen

struct OnboardingView: View {
    @StateObject private var viewModel: OnboardingViewModel

    var onNext: () -> Void
    var onSkip: () -> Void

    // MARK: Init

    init(
        viewModel: OnboardingViewModel = OnboardingViewModel(),
        onNext: @escaping () -> Void = {},
        onSkip: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
        self.onSkip = onSkip
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingBrand.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingIllustrationCard(
                    systemImage: viewModel.currentPageModel.illustration,
                    scale: viewModel.illustrationScale,
                    opacity: viewModel.illustrationOpacity
                )
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 32)

                OnboardingTextSection(
                    title: viewModel.currentPageModel.title,
                    subtitle: viewModel.currentPageModel.subtitle,
                    pageIndex: viewModel.currentPage
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 32)

                OnboardingPageDots(count: viewModel.pages.count, currentIndex: viewModel.currentPage)
                    .padding(.bottom, 32)

                OnboardingNextButton(
                    title: viewModel.isLastPage ? "Get Started" : "Next",
                    pageIndex: viewModel.currentPage,
                    action: { viewModel.advance(onFinish: onNext) }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                OnboardingSkipButton(action: onSkip)
                    .padding(.bottom, 20)
            }
            .opacity(viewModel.contentOpacity)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .onAppear { viewModel.onAppear() }
    }

    // MARK: Swipe gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                viewModel.handleSwipe(translation: value.translation)
            }
    }
}

// MARK: - Previews

#Preview("Page 1 — Welcome") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
