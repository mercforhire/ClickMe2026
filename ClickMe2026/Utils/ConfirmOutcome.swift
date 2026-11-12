//
//  ConfirmOutcome.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Whether a failed `POST /bookings/confirm` tells the app what happened to the
/// booking (`serverCoded`) or leaves it unknown (`outcomeUnknown`).
///
/// Why it matters: the server may have placed the hold and created the booking
/// before the response was lost. A false "unknown" costs at most one idempotent
/// replay (BACK-15 returns the same booking for the same PaymentIntent). A false
/// "coded" resets the paid flow, drops the PaymentIntent id and takes the booking
/// out of the client's view while a hold exists. When unsure, classify as unknown.
/// Android's `PaidFlowError.kt` treats network, decoding and unmapped 5xx the same way.
enum ConfirmOutcome: Equatable {

    /// The request may or may not have reached the booking code. Keep the
    /// PaymentIntent, the `pm_` id and the booking attempt id, and retry the same confirm.
    case outcomeUnknown

    /// The server answered with a code the flow handles. Use `handlePaidFlowError`,
    /// with no automatic retry.
    case serverCoded

    /// Exactly the codes `handlePaidFlowError` has a case for. A 5xx that carries
    /// one of these is the server speaking, not a proxy or an outage, so it is
    /// `serverCoded` (for example 503 `DIRECT_CHARGE_DISABLED`).
    static let explicitlyMappedCodes: Set<ErrorCode> = [
        .paymentRequiresAction,
        .bookingAttemptConflict,
        .intentExpired,
        .piContextMismatch,
        .piAmountMismatch,
        .expertNotBookable,
        .longLeadRequiresSavedCard,
        .longLeadNotAvailable,
        .slotUnavailable,
        .invalidPaymentMethod,
        .meetingLinkUnavailable,
        .directChargeDisabled,
        .paymentFailed,
        .duplicateBooking,
        .amountBelowMinimum,
        .invalidPromo,
        .cannotBookSelf,
    ]

    /// Server codes that leave the outcome unknown whatever their HTTP status (D-17).
    ///
    /// `409 PAYMENT_IN_PROGRESS` is the only 4xx here. `POST /bookings/confirm`
    /// answers it from `classifyConfirmedPI`'s fallback and from
    /// `refetchAfterConfirmConflict` (booking.controller.js) when a concurrent
    /// confirm, or a PaymentIntent that is still settling, stops the server from
    /// finishing the request. The hold may already exist, so the app must not
    /// reset the paid flow. Retrying the same PaymentIntent is safe: the server
    /// either replays the booking it made (BACK-15) or classifies the settled
    /// PaymentIntent.
    static let outcomeUnknownCodes: Set<ErrorCode> = [.paymentInProgress]

    /// Classifies by error type, status and code, never by message text.
    ///
    /// Unknown: any `URLError`, a `CancellationError`, `NetworkError.invalidResponse`
    /// and `.decodingFailed`, an error whose code is in `outcomeUnknownCodes`, and an
    /// HTTP status of 500 or more whose code `handlePaidFlowError` does not map.
    /// Everything else is `serverCoded`.
    static func classify(_ error: Error) -> ConfirmOutcome {
        if error is URLError || error is CancellationError {
            return .outcomeUnknown
        }
        guard let networkError = error as? NetworkError else { return .serverCoded }
        switch networkError {
        case .invalidResponse, .decodingFailed:
            return .outcomeUnknown
        case let .httpError(statusCode, _):
            let code = BookingErrorMapper.code(for: error)
            if let code, outcomeUnknownCodes.contains(code) { return .outcomeUnknown }
            guard statusCode >= 500 else { return .serverCoded }
            if let code, explicitlyMappedCodes.contains(code) { return .serverCoded }
            return .outcomeUnknown
        case .invalidURL, .encodingFailed, .invalidDate:
            return .serverCoded
        }
    }
}
