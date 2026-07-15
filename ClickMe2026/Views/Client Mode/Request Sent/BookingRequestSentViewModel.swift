//
//  BookingRequestSentViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class BookingRequestSentViewModel: ObservableObject {

    // MARK: Content
    let expertName: String
    let topic: String
    let dateTime: String

    // MARK: Entry animation state
    @Published var iconScale: CGFloat
    @Published var iconOpacity: Double
    @Published var bodyOpacity: Double
    @Published var bodyOffset: CGFloat
    @Published var cardOpacity: Double
    @Published var cardOffset: CGFloat
    @Published var btnsOpacity: Double
    @Published var btnsOffset: CGFloat
    @Published var glowPulse: Bool

    init(
        expertName: String = "Sarah Jenkins",
        topic: String = "Advanced UI Architecture",
        dateTime: String = "Oct 24, 2023 | 2:00 PM - 3:00 PM",
        iconScale: CGFloat = 0.50,
        iconOpacity: Double = 0,
        bodyOpacity: Double = 0,
        bodyOffset: CGFloat = 22,
        cardOpacity: Double = 0,
        cardOffset: CGFloat = 18,
        btnsOpacity: Double = 0,
        btnsOffset: CGFloat = 16,
        glowPulse: Bool = false
    ) {
        self.expertName = expertName
        self.topic = topic
        self.dateTime = dateTime
        self.iconScale = iconScale
        self.iconOpacity = iconOpacity
        self.bodyOpacity = bodyOpacity
        self.bodyOffset = bodyOffset
        self.cardOpacity = cardOpacity
        self.cardOffset = cardOffset
        self.btnsOpacity = btnsOpacity
        self.btnsOffset = btnsOffset
        self.glowPulse = glowPulse
    }

    // MARK: Actions

    /// Staggered entry animation: glow pulse → icon spring → headline → card → buttons.
    func runEntryAnimation() {
        glowPulse = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.60).delay(0.10)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.42).delay(0.35)) {
            bodyOpacity = 1
            bodyOffset = 0
        }
        withAnimation(.easeOut(duration: 0.40).delay(0.50)) {
            cardOpacity = 1
            cardOffset = 0
        }
        withAnimation(.easeOut(duration: 0.38).delay(0.64)) {
            btnsOpacity = 1
            btnsOffset = 0
        }
    }
}
