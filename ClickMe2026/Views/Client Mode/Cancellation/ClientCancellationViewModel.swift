//
//  ClientCancellationViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ClientCancellationViewModel: ObservableObject {

    // MARK: View state
    @Published var step: CancelStep
    @Published var selectedReason: String
    @Published var comment: String
    @Published var isConfirming: Bool

    // MARK: Data
    @Published var booking: CancellationBooking
    let reasons: [String]

    init(
        booking: CancellationBooking = ClientCancellationViewModel.sampleBooking,
        step: CancelStep = .reason,
        selectedReason: String = "Change of plans",
        comment: String = "",
        isConfirming: Bool = false,
        reasons: [String] = ClientCancellationViewModel.defaultReasons
    ) {
        self.booking = booking
        self.step = step
        self.selectedReason = selectedReason
        self.comment = comment
        self.isConfirming = isConfirming
        self.reasons = reasons
    }

    // MARK: Actions

    func advanceToConfirmation() {
        withAnimation { step = .confirmation }
    }

    /// Run the submit animation, then forward to the supplied callback.
    /// Networking is intentionally disabled while testing the app flow.
    func confirmCancellation(onConfirm: @escaping (String, String) -> Void) {
        guard !isConfirming else { return }
        withAnimation { isConfirming = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self else { return }
            onConfirm(self.selectedReason, self.comment)
        }
    }

    // MARK: Sample data

    static let defaultReasons: [String] = [
        "Change of plans",
        "Found another expert",
        "Schedule conflict",
        "Personal emergency",
        "Other",
    ]

    static let sampleBooking = CancellationBooking(
        expertName: "Dr. Anya Sharma",
        expertTitle: "Career Coaching",
        dateString: "Wed, Jul 10 • 10:00 AM",
        imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuDOLbdN4ist5Yp2MU-iazD2ggqG2F42GhJKUDhi5omBTMQfsZ3aOtpJMI9x9l_BIc9uFxsR8Lm6fNjwJHuR85wD7jybmImSDCQBOeUITRzo8CARgZN-NnDwUZ5qrRhyWZQyQsu0uapd_3Xun_JTJNPp5yEWCYxukV7kO2-I-WVPLdAIRR18ZAhKbJ-EY4V6bi-sSR4ZWdwvqphktPI2BYaOKzT_05jLA25ati_Shxxg7npPn2mY05T4M16WVkyPp8szqHyPI3yoLBo",
        refundType: "full refund"
    )
}
