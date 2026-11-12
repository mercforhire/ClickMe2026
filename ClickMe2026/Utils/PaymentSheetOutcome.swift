//
//  PaymentSheetOutcome.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Decides whether the card sheet's dismissal means "go ahead and confirm".
///
/// The Stripe FlowController sheet reports `didCancel` true for the close
/// button and tap-outside, and false for its Continue button. A preselected
/// saved card keeps `paymentOption` non-nil even after the client closes the
/// sheet, so `paymentOption` alone cannot tell a close from Continue. Treating
/// it as Continue confirms the booking and places a real hold on a card the
/// client walked away from (PAY-01). A close is a cancel (Q4 settled as cancel,
/// D-01; Android parity).
nonisolated enum PaymentSheetOutcome {

    /// Whether the booking should go on to the setup-mode confirm.
    ///
    /// - Parameters:
    ///   - didCancel: The `didCancel` flag from `presentPaymentOptions(from:completion:)`.
    ///   - hasPaymentOption: Whether the FlowController has a payment option selected.
    /// - Returns: True only for Continue (`didCancel` false) with a payment option.
    static func proceeds(didCancel: Bool, hasPaymentOption: Bool) -> Bool {
        !didCancel && hasPaymentOption
    }
}
