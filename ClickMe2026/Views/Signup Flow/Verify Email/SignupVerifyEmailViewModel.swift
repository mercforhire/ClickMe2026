//
//  SignupVerifyEmailViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SignupVerifyEmailViewModel: ObservableObject {

    let email: String

    // MARK: Resend state
    @Published var isResending: Bool = false
    @Published var didResend: Bool = false
    @Published var resendCooldown: Int = 0

    private var cooldownTask: Task<Void, Never>?

    init(
        email: String = "lucas.anderson@example.com",
        isResending: Bool = false,
        didResend: Bool = false,
        resendCooldown: Int = 0
    ) {
        self.email = email
        self.isResending = isResending
        self.didResend = didResend
        self.resendCooldown = resendCooldown
    }

    // MARK: Resend

    func resend() async {
        guard !isResending, resendCooldown == 0 else { return }

        isResending = true
        try? await Task.sleep(for: .seconds(1.0))
        isResending = false
        didResend = true
        startCooldown(seconds: 30)
    }

    private func startCooldown(seconds: Int) {
        cooldownTask?.cancel()
        resendCooldown = seconds
        cooldownTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, self.resendCooldown > 0 else { return }
                self.resendCooldown -= 1
            }
        }
    }
}
