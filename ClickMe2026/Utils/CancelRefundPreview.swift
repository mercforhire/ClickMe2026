//
//  CancelRefundPreview.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The one rule for the money line on the client cancel confirm step (BOOK-08).
///
/// It previews what the backend will do, it never decides it. The mirrored
/// rules are `computeRefundAmountMinorUnits` in `src/utils/refund.js` and
/// `paymentActionFields` in `src/utils/scaRecovery.js`:
///
/// - A live, uncaptured hold (`payment_status` held with an
///   `authorization_expires_at`) is voided in full at any time, so it reads as
///   a release.
/// - A charged booking is refunded in full only when the start is strictly
///   more than 24 hours away. At exactly 24 hours the refund is zero.
/// - `derivePaymentStatus` keeps reading `held` after the T-24h charge has
///   captured the money, and `authorization_expires_at` is non-null only for a
///   live authorization. So `held` without an expiry is treated as charged.
/// - A booking whose off-session charge is waiting on card authentication
///   (`payment_action_required`), or that has no PaymentIntent
///   (`payment_status` none), has not been charged.
///
/// The amount is the list price (`topic.price.amount`, minor units), not the
/// amount paid. The backend refunds or releases `amount_paid_minor_units`, which
/// is lower when a promo code was applied, and the booking-detail payload does
/// not expose it. So the hold and refund sentences say "up to" the list price
/// instead of stating a firm figure. The post-cancel toast uses the server's
/// real `refund_amount`.
/// The helper never reads the clock; callers pass `now`.
enum CancelRefundPreview {

    /// Refunds are full only when the start is strictly more than this far away.
    static let refundWindow: TimeInterval = 24 * 3600

    /// Second line of the amber block, and the tail of the case D sentence.
    static let withinWindowDetail = "the session starts within 24 hours"

    // MARK: - Facts

    /// The booking-detail fields the rule reads.
    struct Facts: Equatable {
        let isFree: Bool
        let priceAmountMinor: Int?
        let currency: String?
        let paymentStatus: String
        let authorizationExpiresAt: Date?
        let paymentActionRequired: Bool
        let start: Date

        init(
            isFree: Bool,
            priceAmountMinor: Int?,
            currency: String?,
            paymentStatus: String,
            authorizationExpiresAt: Date?,
            paymentActionRequired: Bool,
            start: Date
        ) {
            self.isFree = isFree
            self.priceAmountMinor = priceAmountMinor
            self.currency = currency
            self.paymentStatus = paymentStatus
            self.authorizationExpiresAt = authorizationExpiresAt
            self.paymentActionRequired = paymentActionRequired
            self.start = start
        }

        init(detail: ClientBookingDetail) {
            self.init(
                isFree: detail.topic.isFree,
                priceAmountMinor: detail.topic.price?.amount,
                currency: detail.topic.price?.currency,
                paymentStatus: detail.paymentStatus,
                authorizationExpiresAt: detail.authorizationExpiresAt,
                paymentActionRequired: detail.paymentActionRequired == true,
                start: detail.startTime
            )
        }
    }

    // MARK: - Case

    /// The money cases of the confirm step (UI-SPEC cases A to F). Amounts are
    /// already formatted through `Money`.
    enum Case: Equatable {
        case free
        case liveHold(amount: String)
        case chargedRefundable(amount: String)
        case chargedNotRefundable(zero: String)
        case notChargedYet
        case amountUnknown
    }

    // MARK: - Rule

    /// Chooses the case for a booking at `now`.
    ///
    /// Order: free, then not charged yet (its copy names no amount), then a
    /// missing price or currency, then a live hold, then charged. Any other
    /// `payment_status` (for example `refunded`) falls to `.amountUnknown`.
    static func refundCase(_ facts: Facts, now: Date) -> Case {
        if facts.isFree { return .free }
        if facts.paymentActionRequired || facts.paymentStatus == "none" { return .notChargedYet }

        guard let amount = facts.priceAmountMinor, let currency = facts.currency else {
            return .amountUnknown
        }

        let isLiveHold = facts.paymentStatus == "held" && facts.authorizationExpiresAt != nil
        if isLiveHold {
            return .liveHold(amount: Money.format(minorUnits: amount, currency: currency))
        }

        let isCharged = facts.paymentStatus == "captured" || facts.paymentStatus == "held"
        guard isCharged else { return .amountUnknown }

        // Strict `>` as in refund.js: exactly 24 hours out is not refundable.
        if facts.start.timeIntervalSince(now) > refundWindow {
            return .chargedRefundable(amount: Money.format(minorUnits: amount, currency: currency))
        }
        return .chargedNotRefundable(zero: Money.format(minorUnits: 0, currency: currency))
    }

    // MARK: - Copy

    /// The full sentence for a case, `nil` when the case shows no money line.
    static func text(for refundCase: Case) -> String? {
        switch refundCase {
        case .free:
            return nil
        case .liveHold(let amount):
            return "Up to \(amount) held on your card will be released, so you won't be charged."
        case .chargedRefundable(let amount):
            return "Refund: up to \(amount), cancelled more than 24 hours before the start"
        case .chargedNotRefundable(let zero):
            return "Refund: \(zero), \(withinWindowDetail)"
        case .notChargedYet:
            return "You haven't been charged for this session, so nothing will be charged."
        case .amountUnknown:
            return "Any refund follows our cancellation policy."
        }
    }

    /// The amount substring to set semibold inside `text(for:)`, if any.
    static func emphasis(for refundCase: Case) -> String? {
        switch refundCase {
        case .liveHold(let amount), .chargedRefundable(let amount):
            return amount
        case .chargedNotRefundable(let zero):
            return zero
        case .free, .notChargedYet, .amountUnknown:
            return nil
        }
    }

    /// Whether the "Refunds typically appear..." footnote shows: only when a
    /// refund is actually coming.
    static func showsRefundFootnote(_ refundCase: Case?) -> Bool {
        if case .chargedRefundable = refundCase { return true }
        return false
    }

    /// SF Symbol for the money line, `nil` when there is no line.
    static func iconName(for refundCase: Case) -> String? {
        switch refundCase {
        case .free:
            return nil
        case .liveHold:
            return "lock.fill"
        case .chargedNotRefundable:
            return "exclamationmark.triangle.fill"
        case .chargedRefundable, .notChargedYet, .amountUnknown:
            return "creditcard"
        }
    }
}
