//
//  EarningsTransactionRow.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// One row in the earnings-ledger list. Rendered both on the Payouts
/// screen's compact "Recent activity" section and on the full paginated
/// `TransactionsView`.
///
/// Nullability discipline (per spec §2): every `nil` field renders as
/// `"—"` — the backend deliberately keeps rows whose booking / topic /
/// client can't be resolved rather than dropping them, so the row must
/// still appear.
///
/// Money is in **minor units** on this endpoint (see spec §3), so the
/// formatter divides by the currency's minor-unit exponent from
/// `NumberFormatter.currency` rather than assuming 2.
struct EarningsTransactionRow: View {
    let item: EarningsTransactionItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(topicLabel)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(clientLabel)
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
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                Text(netAmountLabel)
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(Brand.primary)
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

    private var clientLabel: String {
        item.clientName?.nilIfEmpty ?? "—"
    }

    private var dateLabel: String {
        // Prefer the session date; fall back to when the ledger row was
        // created (per spec, `createdAt` is not the session date but
        // it's a reasonable last-resort timestamp when the booking's
        // been orphaned).
        let date = item.sessionDate ?? item.createdAt
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f.string(from: date)
    }

    /// Minor units → user-facing currency string. Drives fraction
    /// digits off `NumberFormatter.currency` so zero-decimal currencies
    /// (JPY, KRW, etc — where `7500` really means ¥7500 not ¥75.00)
    /// render correctly.
    private var netAmountLabel: String {
        Self.formatMinorUnits(item.netAmount, currency: item.currency)
    }

    // MARK: - Status pill

    /// Copy discipline:
    /// - `.settledDirect` → **"Settled"**. Terminal state for direct-
    ///   charge sessions; the earning has been created on the expert's
    ///   Stripe connected-account balance. Do NOT say "Paid" or "In
    ///   your bank" — Stripe holds the funds on its own schedule.
    /// - `.paid` (legacy) → **"Processed"**. Pre-migration rows only;
    ///   meant "platform transferred to the connected account."
    /// - `.pending` / `.processing` → literal labels; legacy rows still
    ///   in flight prior to the direct-charge rollout.
    /// - `.failed` → literal.
    /// - `nil` (unknown future value or missing) → "Unknown" placeholder.
    @ViewBuilder
    private var statusPill: some View {
        switch item.payoutStatus {
        case .pending:
            pill(text: "Pending", tint: .orange)
        case .processing:
            pill(text: "Processing", tint: .blue)
        case .settledDirect:
            pill(text: "Settled", tint: Brand.primary)
        case .paid:
            pill(text: "Processed", tint: Brand.primary)
        case .failed:
            pill(text: "Failed", tint: Brand.error)
        case .none:
            pill(text: "Unknown", tint: Brand.onSurfaceMuted)
        }
    }

    private func pill(text: String, tint: Color) -> some View {
        Text(text)
            .font(.brand(.caption2, weight: .semibold))
            .foregroundColor(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(tint.opacity(0.14)))
    }

    // MARK: - Money formatting

    static func formatMinorUnits(_ minorUnits: Int, currency: String) -> String {
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

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
