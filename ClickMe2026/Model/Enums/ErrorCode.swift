//
//  ErrorCode.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Global enumeration of SCREAMING_SNAKE_CASE error codes the ClickMe API can return.
/// `INVALID_TOKEN` serves two HTTP contexts (401 JWT + 400 deletion-token); the
/// status code distinguishes them.
enum ErrorCode: String, Decodable {
    case missingToken            = "MISSING_TOKEN"
    case invalidToken            = "INVALID_TOKEN"
    case authServiceUnavailable  = "AUTH_SERVICE_UNAVAILABLE"
    case forbidden               = "FORBIDDEN"
    case notFound                = "NOT_FOUND"
    case validationError         = "VALIDATION_ERROR"
    case validationFailed        = "VALIDATION_FAILED"
    case invalidInput            = "INVALID_INPUT"
    case slotUnavailable         = "SLOT_UNAVAILABLE"
    case uploadError             = "UPLOAD_ERROR"
    case internalError           = "INTERNAL_ERROR"
    case invalidStatus           = "INVALID_STATUS"
    case duplicateBooking        = "DUPLICATE_BOOKING"
    case paymentFailed           = "PAYMENT_FAILED"
    case intentExpired           = "INTENT_EXPIRED"
    case piContextMismatch       = "PI_CONTEXT_MISMATCH"
    case piAmountMismatch        = "PI_AMOUNT_MISMATCH"
    case amountBelowMinimum      = "AMOUNT_BELOW_MINIMUM"
    case paidTopicRequiresPayment = "PAID_TOPIC_REQUIRES_PAYMENT"
    case invalidPromo            = "INVALID_PROMO"
    case sessionNotActive        = "SESSION_NOT_ACTIVE"
    case alreadyCancelled        = "ALREADY_CANCELLED"
    case alreadyProcessed        = "ALREADY_PROCESSED"
    case threadBlocked           = "THREAD_BLOCKED"
    case invalidMonth            = "INVALID_MONTH"
    case expertHasUpcomingBookings = "EXPERT_HAS_UPCOMING_BOOKINGS"
    case sessionInProgress       = "SESSION_IN_PROGRESS"
    case emailRequired           = "EMAIL_REQUIRED"
    case confirmationRequired    = "CONFIRMATION_REQUIRED"
    case tokenUserMismatch       = "TOKEN_USER_MISMATCH"
    case refundAmountMissing     = "REFUND_AMOUNT_MISSING"
    case tooManyRequests         = "TOO_MANY_REQUESTS"
    case expiredToken            = "EXPIRED_TOKEN"
}
