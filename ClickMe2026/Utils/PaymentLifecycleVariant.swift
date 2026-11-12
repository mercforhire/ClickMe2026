//
//  PaymentLifecycleVariant.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Which payment story Request Sent's "What happens next" card tells (PAY-03).
///
/// The choice is made from the loaded booking, never assumed. The backend
/// collapses the raw PaymentIntent state into one `payment_status` string
/// (`derivePaymentStatus`, `clientBooking.controller.js`):
///
/// - `none` for no PaymentIntent, a free topic, a voided, expired or failed
///   PaymentIntent under any booking status, and a cancelled, declined or
///   expired booking with no refund.
/// - `held` from the booking status alone (pending_approval, pending_reschedule,
///   confirmed, in_progress), not from the raw payment state.
/// - `captured` for a completed booking, and a missed one with no refund.
/// - `refunded` once a refund lands.
///
/// `authorization_expires_at` is non-null only when the raw state is
/// `requires_capture` with an `authorized_at` (`utils/reschedule.js`).
///
/// The rules, in order:
///
/// - A free topic gets no card.
/// - `held` with an expiry is a live hold (`.liveHold`), the same rule
///   `CancelRefundPreview` uses.
/// - `held` without an expiry gets no card. The raw state may be a hold that
///   has no `authorized_at`, a payment still processing, or money already
///   captured (an older row captured at accept, or a row Sweep C captured while
///   still in progress), and the payload cannot tell them apart. Naming either
///   story could be false, so the card hides.
/// - `captured`, and only `captured`, is `.alreadyCharged`.
/// - `none` is `.chargeScheduled` only on a pending_approval,
///   pending_reschedule or confirmed booking, the only ones that still have a
///   charge ahead of them (an older long-lead booking, or one converted to the
///   charge-at-T-24h model). Any other status hides the card, so a cancelled,
///   declined, expired, missed, completed or started booking is never told a
///   charge is coming.
/// - Anything else, including `refunded`, an empty or a missing value, gets no
///   card.
///
/// `nil` means hide the card (fail closed). The booking status is compared as a
/// raw string because `BookingStatus` is MainActor-isolated under the project's
/// default isolation and this type is `nonisolated`.
nonisolated enum PaymentLifecycleVariant: Equatable {

    /// A hold is on the card; nothing is charged yet.
    case liveHold
    /// No hold; the card is charged about 24 hours before the session.
    case chargeScheduled
    /// The payment has been taken.
    case alreadyCharged

    // MARK: - Chooser

    /// Booking statuses that still have a charge ahead of them.
    private static let chargeScheduledStatuses: Set<String> = [
        "pending_approval", "pending_reschedule", "confirmed"
    ]

    /// Picks the variant for a loaded booking, or `nil` to hide the card.
    ///
    /// - Parameters:
    ///   - isFree: `ClientBookingDetail.topic.isFree`.
    ///   - bookingStatus: The raw `ClientBookingDetail.status`.
    ///   - paymentStatus: The raw `ClientBookingDetail.paymentStatus`.
    ///   - authorizationExpiresAt: `ClientBookingDetail.authorizationExpiresAt`.
    static func choose(
        isFree: Bool,
        bookingStatus: String?,
        paymentStatus: String?,
        authorizationExpiresAt: Date?
    ) -> PaymentLifecycleVariant? {
        if isFree { return nil }

        switch paymentStatus {
        case "held":
            return authorizationExpiresAt != nil ? .liveHold : nil
        case "none":
            guard let bookingStatus, chargeScheduledStatuses.contains(bookingStatus) else { return nil }
            return .chargeScheduled
        case "captured":
            return .alreadyCharged
        default:
            return nil
        }
    }

    // MARK: - Copy

    var stepOneTitle: String {
        switch self {
        case .liveHold:        return "A hold is placed on your card"
        case .chargeScheduled: return "No hold is placed on your card"
        case .alreadyCharged:  return "Your card has been charged"
        }
    }

    var stepOneSubtitle: String {
        switch self {
        case .liveHold:        return "No charge yet — funds are just reserved."
        case .chargeScheduled: return "You haven't been charged yet."
        case .alreadyCharged:  return "Your payment was taken when you booked."
        }
    }

    var stepOneIcon: String {
        switch self {
        case .liveHold:        return "lock.fill"
        case .chargeScheduled: return "creditcard"
        case .alreadyCharged:  return "checkmark.seal.fill"
        }
    }

    var stepThreeTitle: String {
        switch self {
        case .liveHold:        return "Your card is charged after the session"
        case .chargeScheduled: return "Your card is charged before the session"
        case .alreadyCharged:  return "Refunds follow our cancellation policy"
        }
    }

    var stepThreeSubtitle: String {
        switch self {
        case .liveHold:        return "Usually within 15 minutes of the session ending."
        case .chargeScheduled: return "About 24 hours before it starts, unless you cancel first."
        case .alreadyCharged:  return "Cancel more than 24 hours before the start for a full refund."
        }
    }

    var stepThreeIcon: String {
        switch self {
        case .liveHold:        return "checkmark.seal.fill"
        case .chargeScheduled: return "creditcard"
        case .alreadyCharged:  return "creditcard"
        }
    }
}
