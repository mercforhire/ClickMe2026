//
//  ReadyToStartCallViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ReadyToStartCallViewModel: ObservableObject {

    // MARK: Content
    @Published var skypeLink: String

    // MARK: Copy state
    @Published var didCopy: Bool

    // MARK: Entry animation state
    @Published var glowPulse: Bool
    @Published var iconScale: CGFloat
    @Published var iconOpacity: Double
    @Published var bodyOpacity: Double
    @Published var bodyOffset: CGFloat

    init(
        skypeLink: String = "https://join.skype.com/aBcDeFg12345",
        didCopy: Bool = false,
        glowPulse: Bool = false,
        iconScale: CGFloat = 0.80,
        iconOpacity: Double = 0,
        bodyOpacity: Double = 0,
        bodyOffset: CGFloat = 18
    ) {
        self.skypeLink = skypeLink
        self.didCopy = didCopy
        self.glowPulse = glowPulse
        self.iconScale = iconScale
        self.iconOpacity = iconOpacity
        self.bodyOpacity = bodyOpacity
        self.bodyOffset = bodyOffset
    }

    // MARK: Actions

    /// Staggered entry animation: glow pulse → icon spring → headline/CTA slide-up.
    func runEntryAnimation() {
        glowPulse = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.38)) {
            bodyOpacity = 1
            bodyOffset = 0
        }
    }

    /// Copy the Skype link to the pasteboard and briefly show a "Copied" state.
    func copyLink() {
        UIPasteboard.general.string = skypeLink
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation { self?.didCopy = false }
        }
    }
}
