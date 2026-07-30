//
//  ErrorCode.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Canonical enumeration of SCREAMING_SNAKE_CASE error codes the ClickMe
/// API can return. Sourced from the backend's canonical inventory (see
/// auth.controller.js et al) — keep this list in sync when the backend
/// adds new codes. `StandardErrorResponse` / `FieldValidationErrorResponse`
/// decode unknown values to `nil` (lenient) so temporary drift doesn't
/// blank out the user-visible message, but you should still update this
/// file promptly so switch statements over `ErrorCode` stay exhaustive.
///
/// Notes:
/// - `INVALID_TOKEN` serves two HTTP contexts (401 JWT + 400 deletion-
///   token); disambiguate by endpoint, not code.
/// - `TOO_MANY_REQUESTS` (global rate-limits) and `RATE_LIMITED`
///   (`/auth/email/resend` only) are distinct codes with the same 429
///   semantics — check both if you want a unified rate-limit handler.
enum ErrorCode: String, Decodable {

    // MARK: - Auth
    case missingToken            = "MISSING_TOKEN"
    case invalidToken            = "INVALID_TOKEN"
    case invalidCode             = "INVALID_CODE"           // /auth/email/verify + /auth/password/reset — wrong or expired 6-digit code
    case authServiceUnavailable  = "AUTH_SERVICE_UNAVAILABLE"
    case expiredToken            = "EXPIRED_TOKEN"
    case usernameTaken           = "USERNAME_TAKEN"
    case emailTaken              = "EMAIL_TAKEN"

    // MARK: - Generic authz / lookup
    case forbidden               = "FORBIDDEN"
    case notFound                = "NOT_FOUND"
    case noRelationship          = "NO_RELATIONSHIP"

    // MARK: - Validation
    case validationError         = "VALIDATION_ERROR"       // 422 (or 400 on DELETE /user/account), Field envelope
    case validationFailed        = "VALIDATION_FAILED"      // 400, Field envelope (password/forgot)
    case invalidInput            = "INVALID_INPUT"
    case invalidMonth            = "INVALID_MONTH"
    case invalidWeekStart        = "INVALID_WEEK_START"

    // MARK: - Bookings / sessions
    case slotUnavailable         = "SLOT_UNAVAILABLE"
    case duplicateBooking        = "DUPLICATE_BOOKING"
    case invalidStatus           = "INVALID_STATUS"
    case alreadyCancelled        = "ALREADY_CANCELLED"
    case alreadyProcessed        = "ALREADY_PROCESSED"
    case sessionNotActive        = "SESSION_NOT_ACTIVE"
    case sessionInProgress       = "SESSION_IN_PROGRESS"
    case expertHasUpcomingBookings = "EXPERT_HAS_UPCOMING_BOOKINGS"
    case callUnavailable         = "CALL_UNAVAILABLE"       // 503 — Agora not configured

    // MARK: - Chat
    case threadBlocked           = "THREAD_BLOCKED"

    // MARK: - Discovery
    case expertNotFound          = "EXPERT_NOT_FOUND"

    // MARK: - Payments / booking-financial
    case paymentFailed           = "PAYMENT_FAILED"
    case intentExpired           = "INTENT_EXPIRED"
    case piContextMismatch       = "PI_CONTEXT_MISMATCH"
    case piAmountMismatch        = "PI_AMOUNT_MISMATCH"
    case amountBelowMinimum      = "AMOUNT_BELOW_MINIMUM"
    case paidTopicRequiresPayment = "PAID_TOPIC_REQUIRES_PAYMENT"
    case invalidPromo            = "INVALID_PROMO"
    case refundAmountMissing     = "REFUND_AMOUNT_MISSING"

    // MARK: - Payouts / Stripe Connect
    case noPayoutMethod          = "NO_PAYOUT_METHOD"
    case kycIncomplete           = "KYC_INCOMPLETE"
    case insufficientBalance     = "INSUFFICIENT_BALANCE"
    case withdrawInProgress      = "WITHDRAW_IN_PROGRESS"
    case missingIdempotencyKey   = "MISSING_IDEMPOTENCY_KEY"
    case configMissing           = "CONFIG_MISSING"

    // MARK: - Account
    case emailRequired           = "EMAIL_REQUIRED"
    case confirmationRequired    = "CONFIRMATION_REQUIRED"
    case tokenUserMismatch       = "TOKEN_USER_MISMATCH"

    // MARK: - Media
    case uploadError             = "UPLOAD_ERROR"           // 400 (multer) or 413 (LIMIT_FILE_SIZE)

    // MARK: - Rate limiting
    case tooManyRequests         = "TOO_MANY_REQUESTS"      // global rate-limits (login, password reset, delete-request, withdraw, …)
    case rateLimited             = "RATE_LIMITED"           // /auth/email/resend only

    // MARK: - Catch-all
    case internalError           = "INTERNAL_ERROR"
}
