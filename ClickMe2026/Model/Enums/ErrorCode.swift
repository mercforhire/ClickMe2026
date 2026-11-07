//
//  ErrorCode.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    case cannotBookSelf          = "CANNOT_BOOK_SELF"       // 422 — client tried to book themselves
    case expertNotBookable       = "EXPERT_NOT_BOOKABLE"    // 422 — expert not `charges_enabled` yet
    case meetingLinkUnavailable  = "MEETING_LINK_UNAVAILABLE" // 422 — Skype/Zoom link missing on confirm
    // 422 — Rare, terminal reschedule backstop (Phase 27.1). A move
    // past the ~6-day authorization window is no longer refused on its
    // own — the server voids the hold and converts to charge-at-T-24h.
    // This code now fires only when the booking is genuinely
    // unconvertible: no connected account on file, direct charging
    // disabled platform-wide, proposed start < 24h from now, or a
    // legacy card-less booking hit at expert-accept. UX must prompt
    // the user to re-book (not to pick another slot).
    case rescheduleOutsideAuthWindow = "RESCHEDULE_OUTSIDE_AUTH_WINDOW"
    // 422 — Client reschedule / accept-reschedule only (Phase 27.1).
    // The booking has no saved card on file, OR the referenced card
    // exists but cannot be prepared for future billing (typical for a
    // one-off PaymentSheet card confirmed at booking time — that card
    // is single-use on the connected account). This is DB-only on the
    // server — do NOT infer "user has no saved cards" from this code.
    // Recovery: fetch `GET /me/payment-methods`; if non-empty, resend
    // the request with `stripe_payment_method_id` set to the chosen
    // card's id; only fall back to a SetupIntent add-card flow when
    // that list is empty. See `RESCHEDULE-PAYMENT-CONVERSION.md` §3.1.
    case paymentMethodRequired   = "PAYMENT_METHOD_REQUIRED"

    // MARK: - Chat
    case threadBlocked           = "THREAD_BLOCKED"
    /// 403 — `unblock` by the participant who did not block. Reconcile
    /// local state to `is_blocked = true, blocked_by_me = false` and
    /// hide the Unblock affordance. See `docs/ios/CHAT-UNBLOCK.md` §4.
    case notBlocker              = "NOT_BLOCKER"
    /// 422 — `block` or `unblock` against a self-thread. UI should
    /// never show block controls on a self-thread; this is a backstop.
    case cannotBlockSelf         = "CANNOT_BLOCK_SELF"

    // MARK: - Discovery
    case expertNotFound          = "EXPERT_NOT_FOUND"

    // MARK: - Payments / booking-financial
    case paymentFailed             = "PAYMENT_FAILED"
    case paymentRequiresAction     = "PAYMENT_REQUIRES_ACTION"    // 402 — SCA/3DS needed; `detail.client_secret` + (soon) `detail.stripe_account`
    case intentExpired             = "INTENT_EXPIRED"
    case piContextMismatch         = "PI_CONTEXT_MISMATCH"
    case piAmountMismatch          = "PI_AMOUNT_MISMATCH"
    case amountBelowMinimum        = "AMOUNT_BELOW_MINIMUM"       // 422 — Stripe's own per-currency floor (booking flow)
    // 422 — ClickMe's own per-currency floor on topic price. Enforced
    // on topic create/patch AND on both booking-creation paths
    // (short-lead `/bookings/payment-intent`, long-lead
    // `/bookings/confirm`). Distinct from `AMOUNT_BELOW_MINIMUM`
    // (Stripe's floor) — both are live and mean different things.
    // Server message is display-ready + currency-formatted, safe to
    // surface directly.
    case priceBelowMinimum         = "PRICE_BELOW_MINIMUM"
    case paidTopicRequiresPayment  = "PAID_TOPIC_REQUIRES_PAYMENT"
    case invalidPromo              = "INVALID_PROMO"
    case invalidPaymentMethod      = "INVALID_PAYMENT_METHOD"     // 422 — pm_ belongs to a different customer
    case bookingAttemptConflict    = "BOOKING_ATTEMPT_CONFLICT"   // 409 — same booking_attempt_id, different details
    // 422 — `POST /bookings/payment-intent` only (Phase 27.1). Session
    // start is > 6 days out; the manual-capture PI flow cannot cover
    // that lead time. Do NOT retry `/payment-intent`. Switch to the
    // save-card path: call `POST /bookings/confirm` **without** a
    // `payment_intent_id` — the server routes it to the long-lead /
    // charge-at-T-24h branch. Requires the client to have a saved
    // card already (our booking gate ensures this).
    case longLeadRequiresSavedCard = "LONG_LEAD_REQUIRES_SAVED_CARD"
    case commissionNotConfigured   = "COMMISSION_NOT_CONFIGURED"  // 500 — server config issue
    case directChargeDisabled      = "DIRECT_CHARGE_DISABLED"     // 503 — server kill switch
    case refundAmountMissing       = "REFUND_AMOUNT_MISSING"

    // MARK: - Payouts / Stripe Connect
    case noPayoutMethod          = "NO_PAYOUT_METHOD"
    case kycIncomplete           = "KYC_INCOMPLETE"
    case configMissing           = "CONFIG_MISSING"
    case invalidCountry          = "INVALID_COUNTRY"        // 422 — non-CA account on onboard
    case connectNotRatified      = "CONNECT_NOT_RATIFIED"   // 403 — live-mode legal gate

    // MARK: - Endpoint lifecycle
    case endpointRetired         = "ENDPOINT_RETIRED"       // 410 — retired endpoint (e.g. expert withdraw)

    // MARK: - Account
    case emailRequired           = "EMAIL_REQUIRED"
    case confirmationRequired    = "CONFIRMATION_REQUIRED"
    case tokenUserMismatch       = "TOKEN_USER_MISMATCH"

    // MARK: - Account suspension & counterparty unavailability
    // See `docs/ios/USER-REPORTING.md`.
    /// 403 — the caller's own account was suspended. Returned on ANY
    /// authed request and on `/auth/login`. Networking layer should
    /// trap this globally: clear tokens, disconnect socket, route to
    /// the suspension screen.
    case accountSuspended        = "ACCOUNT_SUSPENDED"
    /// 422 — tried to report self. Hide the Report action on the
    /// user's own profile.
    case cannotReportSelf        = "CANNOT_REPORT_SELF"
    /// 409 — booking endpoints when the target expert was suspended
    /// or terminated between discovery and action. Return to Explore
    /// with "This expert is no longer available."
    case expertUnavailable       = "EXPERT_UNAVAILABLE"
    /// 409 — expert accept-reschedule when the client was suspended
    /// or terminated. Symmetric with `expertUnavailable`.
    case clientUnavailable       = "CLIENT_UNAVAILABLE"
    /// 403 — `POST /chats/:id/send` when the recipient is unavailable.
    /// Disable the message composer: "This user is unavailable."
    case recipientUnavailable    = "RECIPIENT_UNAVAILABLE"

    // MARK: - Media
    case uploadError             = "UPLOAD_ERROR"           // 400 (multer) or 413 (LIMIT_FILE_SIZE)

    // MARK: - Rate limiting
    case tooManyRequests         = "TOO_MANY_REQUESTS"      // global rate-limits (login, password reset, delete-request, withdraw, …)
    case rateLimited             = "RATE_LIMITED"           // /auth/email/resend only

    // MARK: - Catch-all
    case internalError           = "INTERNAL_ERROR"
}
