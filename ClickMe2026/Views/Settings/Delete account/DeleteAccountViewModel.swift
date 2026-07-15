//
//  DeleteAccountViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-29.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class DeleteAccountViewModel: ObservableObject {

    // MARK: Flow state
    @Published var step: DeleteAccountStep

    // MARK: Feedback form state
    @Published var selectedReason: String
    @Published var additionalComments: String
    @Published var isDeleting: Bool

    let reasons: [String]

    init(
        step: DeleteAccountStep = .confirmation,
        selectedReason: String = "",
        additionalComments: String = "",
        isDeleting: Bool = false,
        reasons: [String] = DeleteAccountViewModel.defaultReasons
    ) {
        self.step = step
        self.selectedReason = selectedReason
        self.additionalComments = additionalComments
        self.isDeleting = isDeleting
        self.reasons = reasons
    }

    // MARK: Actions

    func advanceToFeedback() {
        withAnimation { step = .feedback }
    }

    /// Run the deletion choreography: spinner → "deleted" screen.
    /// Networking is intentionally disabled while testing the app flow.
    func confirmDeletion() {
        withAnimation { isDeleting = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            withAnimation { self?.step = .deleted }
        }
    }

    // MARK: Defaults

    static let defaultReasons: [String] = [
        "Too expensive",
        "Found an alternative",
        "Privacy concerns",
        "Other",
    ]
}
