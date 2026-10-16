//
//  ClientTransactionRow.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// One row in the client-side payment history list. Mirrors the shape
/// of the expert-side `EarningsTransactionRow` (topic + peer on the
/// left, amount + status pill on the right) so the two ledgers feel
/// like siblings.
///
/// Nullability discipline (spec §"Rendering rule"): every nullable
/// field falls back to `"—"`. The row is always rendered — the
/// backend deliberately never drops a row on unresolvable joins.
///
/// Amounts are minor units → formatted via `ClientTransactionItem`'s
/// `formattedAmount` helper (currency-aware, JPY-safe).
struct ClientTransactionRow: View {
    let item: ClientTransactionItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(topicLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(expertLabel)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .lineLimit(1)
                    Text("·")
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                    Text(dateLabel)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.onSurfaceVariant)
                        .lineLimit(1)
                }

                if item.isPartialRefund {
                    // Show the refunded portion inline as a subtle
                    // subtitle so a partial refund is discoverable
                    // without tapping through to the booking.
                    Text("Refunded \(item.formattedRefundedAmount)")
                        .font(.brand(.caption2, weight: .regular))
                        .foregroundColor(Brand.onSurfaceMuted)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.formattedAmount)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(amountColor)
                    .lineLimit(1)
                statusPill
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }

    // MARK: - Derived labels

    private var topicLabel: String {
        item.topicTitle?.nilIfEmpty ?? "—"
    }

    private var expertLabel: String {
        item.expertName?.nilIfEmpty ?? "—"
    }

    private var dateLabel: String {
        // Prefer the session date (what the client thinks of as "when
        // was that session"). Fall back to `createdAt` for orphaned
        // rows where the booking can't be resolved — that's the
        // transaction timestamp, per spec.
        let date = item.sessionDate ?? item.createdAt
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    /// Amount color signals the money direction:
    /// - Refunded (fully) → muted, since it returned
    /// - Otherwise → onSurface (neutral emphasis)
    private var amountColor: Color {
        if item.paymentStatus == "refunded" {
            return Brand.onSurfaceMuted
        }
        return Brand.onSurface
    }

    // MARK: - Status pill

    /// Pill color mapping per the spec's suggested labels. Money-out
    /// states (`captured`) use brand green because the payment
    /// completed successfully; money-held (`requires_capture`,
    /// `processing`, `scheduled`) uses amber to distinguish
    /// "authorized but not charged"; failure / cancel / expired uses
    /// error red; refund uses a neutral muted tone. Unknown future
    /// values fall through to a neutral placeholder rather than
    /// crashing the render.
    @ViewBuilder
    private var statusPill: some View {
        switch item.paymentStatus {
        case "captured":
            pill(text: item.statusLabel, tint: Brand.primary)
        case "requires_capture", "processing", "scheduled":
            pill(text: item.statusLabel, tint: .orange)
        case "refunded", "partially_refunded":
            pill(text: item.statusLabel, tint: Brand.onSurfaceVariant)
        case "failed", "canceled", "auth_expired":
            pill(text: item.statusLabel, tint: Brand.error)
        case "requires_payment_method":
            pill(text: item.statusLabel, tint: .orange)
        case "none":
            // Legacy-row case — copy adapts based on whether there's a
            // real amount, so re-use the item's own label logic.
            pill(text: item.statusLabel, tint: Brand.onSurfaceMuted)
        default:
            // Unknown future value — spec says treat as neutral
            // pass-through, don't crash the decode or the render.
            pill(text: "—", tint: Brand.onSurfaceMuted)
        }
    }

    private func pill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.brand(.caption2, weight: .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint.opacity(0.14)))
            .lineLimit(1)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
