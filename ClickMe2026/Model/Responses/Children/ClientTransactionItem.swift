//
//  ClientTransactionItem.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Single row from `GET /client/transactions` — the client-side payment
/// history ledger. One row per booking, refunds inline (see `refundedAmount`).
///
/// **Amounts are in minor units** (spec §6) — `7500` means `$75.00`.
/// Format decimal places off `currency`, not a hard-coded 2, so JPY / KRW
/// / VND etc render as `¥7500` not `¥75.00`.
///
/// **`paymentStatus` is stored as the raw string**, not a Swift enum.
/// Deliberate: the backend's payment state machine has 11 values today
/// and the spec (§3) warns it can gain more. A `String, Decodable` enum
/// would `throw` on any unknown raw value and break the entire list
/// decode; storing the raw string means new server-side values just
/// render as `"—"` until we teach `statusLabel` to handle them. The
/// spec's Swift starting point recommends this shape.
///
/// **Do NOT reuse the 4-value `payment_status` enum from
/// `GET /client/bookings/:id`** — the spec explicitly calls out sharing
/// as the most likely thing to go wrong. That endpoint collapses
/// `failed`, `canceled`, `auth_expired`, and `scheduled` all to `none`,
/// which would tell a client whose card was declined that nothing
/// happened. This endpoint deliberately does not collapse — every
/// attempt is a row.
struct ClientTransactionItem: Decodable, Identifiable, Equatable {

    /// SwiftUI `Identifiable` — use the booking id since each row is
    /// scoped to one booking. Deep-link key back to the booking detail.
    var id: UUID { bookingId }

    let bookingId: UUID
    /// The scheduled session start time — NOT the transaction date.
    /// Use `createdAt` for when the charge happened. `nil` when the
    /// booking can no longer be resolved (deleted / orphaned).
    let sessionDate: Date?
    /// `nil` when the topic can't be resolved. Render as `"—"`; keep
    /// the row (spec §2 rendering rule).
    let topicTitle: String?
    /// `"First Last"` or just `"First"` when only a first name is on
    /// file. `nil` when the expert profile can't be resolved.
    let expertName: String?
    /// Absolute Supabase storage URL. `nil` when unavailable.
    let expertAvatarUrl: URL?
    /// Minor units. **`nil`** = no amount ever set (e.g. a `scheduled`
    /// row before its PaymentIntent existed). Render as `"—"`, NOT
    /// `"$0.00"` (spec §"Field table" note on `amount`).
    let amount: Int?
    /// ISO-4217 uppercase. Backend falls back to `"CAD"` when
    /// unspecified, so this is always populated.
    let currency: String
    /// Raw 11-value payment state machine — see `statusLabel` for the
    /// mapping to display copy. Stored as `String` (not enum) for
    /// forward-compat with future server-side values.
    let paymentStatus: String
    /// Minor units. Defaults to `0` when no refund. See `isRefunded` /
    /// `isPartialRefund` for higher-level classification. Do NOT use
    /// `refundedAt` to detect refunds — that field is always nil
    /// (spec §5, placeholder for forward compat).
    let refundedAmount: Int
    /// When funds were actually captured. `nil` until capture. Rows
    /// still in `.requiresCapture` / `.processing` / `.scheduled` /
    /// etc all have this as nil.
    let paidAt: Date?
    /// **Always `nil`** — placeholder field for forward compatibility
    /// (spec §5). No refund-timestamp column exists in the backend
    /// schema. Never render a refund date from this — use
    /// `refundedAmount` and `paymentStatus` to describe a refund.
    let refundedAt: Date?
    /// When the transaction row was inserted. Serves double duty as
    /// both the row's user-visible "date" and the pagination sort key
    /// (server orders `created_at DESC, id DESC`).
    let createdAt: Date

    // MARK: - Display helpers

    /// User-facing status label per the spec's §3 table + §4 legacy-
    /// row rule for `"none"` with a real amount.
    ///
    /// The `"none"` branch is the live-data caveat: production still
    /// has legacy bookings where the status column was never
    /// backfilled — a real $50 charge can display as `"none"`. When
    /// that happens (`amount > 0`), we render as "Processed" so we
    /// don't tell the user their real payment didn't happen. Only
    /// treat as a true no-payment state when the row genuinely has no
    /// amount.
    var statusLabel: String {
        switch paymentStatus {
        case "captured":               return "Paid"
        case "requires_capture":       return "Authorized (not yet charged)"
        case "scheduled":              return "Scheduled"
        case "processing":             return "Processing"
        case "requires_payment_method": return "Payment needed"
        case "refunded":               return "Refunded"
        case "partially_refunded":     return "Partially refunded"
        case "failed":                 return "Payment failed"
        case "canceled":               return "Canceled"
        case "auth_expired":           return "Authorization expired"
        case "none":
            // Legacy-row fallback per spec §4. A real charge can still
            // report `none` — differentiate by amount.
            return (amount ?? 0) > 0 ? "Processed" : "No payment"
        default:
            return "—"
        }
    }

    /// True when any money has been returned. Prefer this over reading
    /// `refundedAt` (which is always nil per §5).
    var isRefunded: Bool { refundedAmount > 0 }

    /// True when a refund landed but didn't cover the whole charge.
    /// Requires a real captured amount to compare against — a `nil`
    /// or zero amount can't be partially refunded by definition.
    var isPartialRefund: Bool {
        guard let amount, amount > 0 else { return false }
        return refundedAmount > 0 && refundedAmount < amount
    }

    /// Format `amount` as a currency string using the row's own
    /// `currency`. Drives fraction-digit count off `NumberFormatter`
    /// so zero-decimal currencies (JPY, KRW, VND, CLP, ISK, XOF, XAF)
    /// render correctly. `nil` amount → `"—"` (never `"$0.00"`).
    var formattedAmount: String {
        Self.format(minorUnits: amount, currency: currency)
    }

    /// Same formatter applied to the refunded amount — used by row
    /// subtitles that break out the refund figure inline.
    var formattedRefundedAmount: String {
        Self.format(minorUnits: refundedAmount, currency: currency)
    }

    private static func format(minorUnits: Int?, currency: String) -> String {
        guard let minorUnits else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        let digits = formatter.maximumFractionDigits
        let divisor: Double = pow(10.0, Double(digits))
        let major = Double(minorUnits) / divisor
        return formatter.string(from: NSNumber(value: major))
            ?? "\(currency) \(major)"
    }
}
