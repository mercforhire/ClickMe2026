//
//  ExpertCancelRefundLine.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-11.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The client-money line on the expert cancel sheet (EXP-11).
///
/// An expert-initiated cancel always releases the client's hold or refunds
/// the payment in full (D-07, Phase 1 D-17 / BACK-19, `cancelExpertBooking`
/// in `expertBooking.controller.js`). The sheet may say so only when the
/// details payload proves money is held or was taken:
///
/// - D-14: `payment_action_required` is the boolean derived from the backend's
///   `paymentActionFields`. True means a charge is waiting on the client's card
///   authentication and nothing was charged. A payload that lacks the key
///   (backend not deployed) is unknown, so the rule fails closed.
/// - D-16: `payment_not_charged` is true when no money is held on or taken from
///   the client's card, for example a free booking or one converted to long-lead
///   by an accepted reschedule (`convertToLongLead` nulls `payment_intent_id`
///   and voids the hold). Missing key is unknown, so the rule fails closed.
///
/// The only route to a money line is both keys present and false. Every other
/// combination returns `.none`: no sentence and no footnote.
enum ExpertCancelRefundLine: Equatable {
    /// No client-money claim. Free booking, nothing charged, or unknown.
    case none
    /// A live authorization: it is released, nothing was charged.
    case holdReleased(amount: String?)
    /// A captured payment: refunded in full.
    case fullRefund(amount: String?)

    // MARK: - Rule

    /// - Parameters:
    ///   - consultationAmountMajor: `session.consultationFee.amount`, major units.
    ///   - currency: `session.consultationFee.currency`.
    ///   - authorizationExpiresAt: non-nil only for a live hold.
    ///   - paymentActionRequired: `payment_action_required`; nil when the payload lacks the key.
    ///   - paymentNotCharged: `payment_not_charged`; nil when the payload lacks the key.
    static func make(
        consultationAmountMajor: Double,
        currency: String,
        authorizationExpiresAt: Date?,
        paymentActionRequired: Bool?,
        paymentNotCharged: Bool?
    ) -> ExpertCancelRefundLine {
        guard consultationAmountMajor > 0 else { return .none }

        switch (paymentActionRequired, paymentNotCharged) {
        case (false?, false?):
            let amount = Money.format(major: consultationAmountMajor, currency: currency)
            return authorizationExpiresAt != nil ? .holdReleased(amount: amount) : .fullRefund(amount: amount)
        default:
            return .none
        }
    }

    // MARK: - Presentation

    /// The full sentence, or nil when the sheet shows no money row.
    var text: String? {
        switch self {
        case .none:
            return nil
        case let .holdReleased(amount):
            guard let amount else { return "The client's hold will be released." }
            return "The client's \(amount) hold will be released."
        case let .fullRefund(amount):
            guard let amount else { return "The client will get a full refund." }
            return "The client will get a full refund of \(amount)"
        }
    }

    /// The amount substring, set semibold inside `text`.
    var emphasis: String? {
        switch self {
        case .none: return nil
        case let .holdReleased(amount), let .fullRefund(amount): return amount
        }
    }

    var iconName: String? {
        switch self {
        case .none: return nil
        case .holdReleased: return "lock.fill"
        case .fullRefund: return "creditcard"
        }
    }

    /// "Refunds typically appear ..." belongs to the refund line only.
    var showsFootnote: Bool {
        if case .fullRefund = self { return true }
        return false
    }
}
