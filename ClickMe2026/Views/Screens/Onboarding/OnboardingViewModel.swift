//
//  OnboardingViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: Published state

    @Published var currentPage: Int = 0
    @Published var contentOpacity: Double = 0
    @Published var illustrationScale: CGFloat = 0.88
    @Published var illustrationOpacity: Double = 0

    // MARK: Content

    let pages: [OnboardingPage] = [
        OnboardingPage(
            illustration: .welcome,
            title: "Welcome to ClickMe",
            subtitle: "Connect with top experts in your field for personalized advice and guidance."
        ),
        OnboardingPage(
            illustration: .discover,
            title: "Discover Top Experts",
            subtitle: "Find the right professionals for your needs across dozens of specialized categories."
        ),
        OnboardingPage(
            illustration: .booking,
            title: "Book & Schedule Instantly",
            subtitle: "Secure your appointments and payments with ease through our integrated platform."
        ),
        OnboardingPage(
            illustration: .communication,
            title: "Seamless Communication",
            subtitle: "Connect via chat, voice, or video calls directly within the app to get the advice you need."
        ),
    ]

    // MARK: Derived

    var isLastPage: Bool { currentPage == pages.count - 1 }

    var currentPageModel: OnboardingPage { pages[currentPage] }

    // MARK: Lifecycle

    /// Called from the view's `.onAppear`. Fades content in and kicks off the
    /// first illustration animation.
    func onAppear() {
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            contentOpacity = 1
        }
        animateIllustration()
    }

    // MARK: Page navigation

    /// Advances to the next page, or invokes `onFinish` on the last page.
    func advance(onFinish: () -> Void) {
        if isLastPage {
            onFinish()
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentPage += 1
            }
            animateIllustration()
        }
    }

    /// Handles the swipe drag end. Ignores gestures that were mostly vertical
    /// or below the horizontal threshold.
    func handleSwipe(translation: CGSize) {
        let horizontal = translation.width
        let vertical = translation.height
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
