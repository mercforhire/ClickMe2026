//
//  CancelToastMessage.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The toast shown after a client cancel succeeds (BOOK-08, D-06; UI-SPEC
/// post-cancel table).
///
/// The wording follows the server's `refund_amount`, not the preview. The
/// backend returns 0 for a released hold, a free booking, a within-24-hours
/// charge, and while a failed void or refund is being retried, so a 0 is never
/// worded "no refund" except for the case the client confirmed under as
/// charged inside 24 hours (`.chargedNotRefundable`).
///
/// Under `.chargedRefundable` a server 0 is worded neutrally, with no amount
/// and no timing. The case was chosen with the phone's clock, while the server
/// applies its strict more-than-24-hours rule with its own clock. A refund
/// being retried and the idempotent already-cancelled 200 also return 0, and
/// the response cannot tell these apart. An amount is named only when the
/// server's amount is above 0 (WR-02).
nonisolated enum CancelToastMessage {

    /// - Parameters:
    ///   - serverRefundMajor: `data.refund_amount` from the cancel response, in major units.
    ///   - currency: `data.currency` from the same response.
    ///   - confirmedCase: The case the client last saw on the confirm step.
    static func text(
        serverRefundMajor: Double,
        currency: String,
        confirmedCase: CancelRefundPreview.Case
    ) -> String {
        let base = "Booking cancelled."

        if serverRefundMajor > 0 {
            guard let amount = Money.format(major: serverRefundMajor, currency: currency) else {
                return base
            }
            return "\(base) \(amount) will be refunded to your card."
        }

        switch confirmedCase {
        case .free, .amountUnknown:
            return base
        case .liveHold(let amount):
            return "\(base) Up to \(amount) held on your card is being released."
        case .chargedRefundable:
            return "\(base) Any refund due will follow our cancellation policy."
        case .chargedNotRefundable:
            return "\(base) No refund applies because the session was within 24 hours."
        case .notChargedYet:
            return "\(base) You weren't charged."
        }
    }
}
