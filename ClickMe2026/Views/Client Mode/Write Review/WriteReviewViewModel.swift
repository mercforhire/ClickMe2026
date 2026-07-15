//
//  WriteReviewViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class WriteReviewViewModel: ObservableObject {

    // MARK: View state
    @Published var selectedStars: Int
    @Published var hoverStar: Int
    @Published var reviewText: String
    @Published var isSubmitting: Bool
    @Published var didSubmit: Bool
    @Published var glowPulse: Bool
    @Published var starsAnimated: Bool

    init(
        selectedStars: Int = 5,
        hoverStar: Int = 0,
        reviewText: String = "",
        isSubmitting: Bool = false,
        didSubmit: Bool = false,
        glowPulse: Bool = false,
        starsAnimated: Bool = false
    ) {
        self.selectedStars = selectedStars
        self.hoverStar = hoverStar
        self.reviewText = reviewText
        self.isSubmitting = isSubmitting
        self.didSubmit = didSubmit
        self.glowPulse = glowPulse
        self.starsAnimated = starsAnimated
    }

    // MARK: Actions

    func selectStar(_ star: Int) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.55)) {
            selectedStars = star
        }
    }

    /// Run the submit animation, then forward to the supplied callback.
    /// Networking is intentionally disabled while testing the app flow.
    func submit(onSubmit: @escaping (Int, String) -> Void) {
        guard !isSubmitting, !didSubmit else { return }
        withAnimation(.easeInOut(duration: 0.2)) { isSubmitting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSubmitting = false
                self.didSubmit = true
            }
            onSubmit(self.selectedStars, self.reviewText)
        }
    }
}
