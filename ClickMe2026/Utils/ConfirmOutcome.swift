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

    /// Classifies by error type and status, never by message text.
    ///
    /// Unknown: any `URLError`, a `CancellationError`, `NetworkError.invalidResponse`
    /// and `.decodingFailed`, and an HTTP status of 500 or more whose code
    /// `handlePaidFlowError` does not map. Everything else is `serverCoded`.
    static func classify(_ error: Error) -> ConfirmOutcome {
        if error is URLError || error is CancellationError {
            return .outcomeUnknown
        }
        guard let networkError = error as? NetworkError else { return .serverCoded }
        switch networkError {
        case .invalidResponse, .decodingFailed:
            return .outcomeUnknown
        case let .httpError(statusCode, _):
            guard statusCode >= 500 else { return .serverCoded }
            if let code = BookingErrorMapper.code(for: error), explicitlyMappedCodes.contains(code) {
                return .serverCoded
            }
            return .outcomeUnknown
        case .invalidURL, .encodingFailed, .invalidDate:
            return .serverCoded
        }
    }
}
