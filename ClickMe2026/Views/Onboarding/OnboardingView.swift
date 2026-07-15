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
    @State private var currentPage: Int = 0
    @State private var contentOpacity: Double = 0
    @State private var illustrationScale: CGFloat = 0.88
    @State private var illustrationOpacity: Double = 0

    var onNext: () -> Void
    var onSkip: () -> Void

    // MARK: Pages

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            illustration: "bubble.left.and.text.bubble.right.fill",
            title: "Welcome to ClickMe",
            subtitle: "Connect with top experts in your field for personalized advice and guidance."
        ),
        OnboardingPage(
            illustration: "magnifyingglass.circle.fill",
            title: "Discover Top Experts",
            subtitle: "Find the right professionals for your needs across dozens of specialized categories."
        ),
        OnboardingPage(
            illustration: "calendar.badge.checkmark",
            title: "Book & Schedule Instantly",
            subtitle: "Secure your appointments and payments with ease through our integrated platform."
        ),
        OnboardingPage(
            illustration: "bubble.left.and.bubble.right.fill",
            title: "Seamless Communication",
            subtitle: "Connect via chat, voice, or video calls directly within the app to get the advice you need."
        ),
    ]

    // MARK: Init

    init(onNext: @escaping () -> Void = {}, onSkip: @escaping () -> Void = {}) {
        self.onNext = onNext
        self.onSkip = onSkip
    }

    // MARK: Body

    var body: some View {
        ZStack(alignment: .bottom) {
            OnboardingBrand.surface.ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingIllustrationCard(
                    systemImage: pages[currentPage].illustration,
                    scale: illustrationScale,
                    opacity: illustrationOpacity
                )
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 32)

                OnboardingTextSection(
                    title: pages[currentPage].title,
                    subtitle: pages[currentPage].subtitle,
                    pageIndex: currentPage
                )
                .padding(.horizontal, 20)

                Spacer(minLength: 32)

                OnboardingPageDots(count: pages.count, currentIndex: currentPage)
                    .padding(.bottom, 32)

                OnboardingNextButton(
                    title: isLastPage ? "Get Started" : "Next",
                    pageIndex: currentPage,
                    action: advance
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                OnboardingSkipButton(action: onSkip)
                    .padding(.bottom, 20)
            }
            .opacity(contentOpacity)
        }
        .contentShape(Rectangle())
        .gesture(swipeGesture)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                contentOpacity = 1
            }
            animateIllustration()
        }
    }

    // MARK: Page navigation

    private var isLastPage: Bool { currentPage == pages.count - 1 }

    private func advance() {
        if isLastPage {
            onNext()
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPage += 1
            }
            animateIllustration()
        }
    }

    // MARK: Swipe gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                // Ignore if the gesture was mostly vertical
                guard abs(horizontal) > abs(vertical) else { return }
                let threshold: CGFloat = 60
                if horizontal < -threshold, currentPage < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage += 1
                    }
                    animateIllustration()
                } else if horizontal > threshold, currentPage > 0 {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage -= 1
                    }
                    animateIllustration()
                }
            }
    }

    // MARK: Illustration animation helper

    private func animateIllustration() {
        illustrationScale = 0.85
        illustrationOpacity = 0
        withAnimation(.spring(response: 0.55, dampingFraction: 0.70).delay(0.05)) {
            illustrationScale = 1.0
            illustrationOpacity = 1.0
        }
    }
}

// MARK: - Previews

#Preview("Page 1 — Welcome") {
    OnboardingView()
        .preferredColorScheme(.dark)
}
