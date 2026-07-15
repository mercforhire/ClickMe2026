//
//  RequestDecisionViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class RequestDecisionViewModel {
    // MARK: Data

    var request: IncomingRequest
    var clientMessage: String
    var potentialEarnings: Double

    // MARK: Sheet state

    var showAcceptSheet = false
    var showDeclineSheet = false

    // MARK: Button feedback

    var isAccepted = false
    var isDeclined = false

    // MARK: Actions

    var onAccept: (IncomingRequest) -> Void
    var onDecline: (IncomingRequest) -> Void
    var onMessage: (IncomingRequest) -> Void
    var onViewProfile: (IncomingRequest) -> Void

    // MARK: Init

    init(
        request: IncomingRequest = IncomingRequest.samples[0],
        clientMessage: String = "Hi, I'm really looking forward to our session. I'd love to discuss my career path and get your advice on breaking into the design industry. Thanks!",
        potentialEarnings: Double = 75.0,
        onAccept: @escaping (IncomingRequest) -> Void = { _ in },
        onDecline: @escaping (IncomingRequest) -> Void = { _ in },
        onMessage: @escaping (IncomingRequest) -> Void = { _ in },
        onViewProfile: @escaping (IncomingRequest) -> Void = { _ in }
    ) {
        self.request = request
        self.clientMessage = clientMessage
        self.potentialEarnings = potentialEarnings
        self.onAccept = onAccept
        self.onDecline = onDecline
        self.onMessage = onMessage
        self.onViewProfile = onViewProfile
    }

    // MARK: Intents

    func openAcceptSheet() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAcceptSheet = true
        }
    }

    func openDeclineSheet() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showDeclineSheet = true
        }
    }

    func dismissSheets() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAcceptSheet = false
            showDeclineSheet = false
        }
    }

    func confirmAccept() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showAcceptSheet = false
        }
        withAnimation(.easeInOut(duration: 0.25).delay(0.15)) {
            isAccepted = true
        }
        onAccept(request)
    }

    func confirmDecline() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            showDeclineSheet = false
        }
        withAnimation(.easeInOut(duration: 0.25).delay(0.15)) {
            isDeclined = true
        }
        onDecline(request)
    }

    func messageTapped() {
        onMessage(request)
    }

    func viewProfileTapped() {
        onViewProfile(request)
    }
}
