//
//  BookingConfirmedViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class BookingConfirmedViewModel {
    var checkScale: CGFloat = 0.40
    var checkOpacity: Double = 0
    var textOpacity: Double = 0
    var textOffset: CGFloat = 20
    var cardOpacity: Double = 0
    var cardOffset: CGFloat = 18
    var btnOpacity: Double = 0
    var btnOffset: CGFloat = 16
    var glowPulse: Bool = false

    func runEntryAnimation() {
        // 1. Check bounces in
        withAnimation(.spring(response: 0.55, dampingFraction: 0.58).delay(0.1)) {
            checkScale = 1.0
            checkOpacity = 1.0
        }
        // 2. Text slides up
        withAnimation(.easeOut(duration: 0.45).delay(0.40)) {
            textOpacity = 1
            textOffset = 0
        }
        // 3. Card slides up
        withAnimation(.easeOut(duration: 0.42).delay(0.55)) {
            cardOpacity = 1
            cardOffset = 0
        }
        // 4. Buttons slide up
        withAnimation(.easeOut(duration: 0.40).delay(0.68)) {
            btnOpacity = 1
            btnOffset = 0
        }
        // 5. Glow pulse starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.80) { [weak self] in
            self?.glowPulse = true
        }
    }
}
