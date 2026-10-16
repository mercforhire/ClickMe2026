//
//  RequestDecisionEarningsSection.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Receipt-style earnings breakdown for the incoming-request screen.
/// Renders the take-home as the headline number with the platform
/// commission shown explicitly — the spec (`§4`) is deliberate that
/// surfacing the fee line is better UX than a silent smaller net, which
/// experts tend to read as a rate cut.
///
/// Three branches, keyed off `EarningsBreakdown.feeSource`:
/// - `.booking` → exact commission locked to this booking; state the
///   net plainly.
/// - `.expertDefault` → derived from the expert's configured rate for
///   an un-charged long-lead booking; qualify the net with `≈` and a
///   small "estimated" caption.
/// - `.unavailable` → no rate resolvable; show session price + a
///   "Payout amount pending" caption. `grossAmount` **must not** be
///   shown under an "earnings" label as a fallback.
///
/// If the whole breakdown object is `nil` (very old cached response),
/// fall through to the `.unavailable` treatment using the legacy gross
/// value the caller passes in.
struct RequestDecisionEarningsSection: View {

    /// Post-commission breakdown from the backend. Nil for pre-rollout
    /// cached responses — the view falls through to the "pending"
    /// treatment.
    let breakdown: EarningsBreakdown?
    /// Legacy gross session fee, used only for the `.unavailable` and
    /// nil-breakdown paths where we render the client-facing session
    /// price instead of an earnings figure.
    let fallbackGross: Double
    /// ISO-4217 currency for the fallback path. The breakdown's own
    /// `currency` is used when present.
    let fallbackCurrency: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Earnings")
                .font(.brand(.body, weight: .bold))
                .foregroundColor(Brand.onSurface)

            card
        }
    }

    // MARK: - Router

    /// Nil `feeSource` (missing breakdown) is treated the same as
    /// `.unavailable` per the spec — never fall back to gross-as-net.
    @ViewBuilder
    private var card: some View {
        switch breakdown?.feeSource {
        case .booking:
            populatedCard(qualifier: nil)
        case .expertDefault:
            populatedCard(qualifier: .estimated)
        case .unavailable, nil:
            pendingCard
        }
    }

    // MARK: - Populated card (booking / expert_default)

    /// The full receipt: gross → fee → net. Only used when we have real
    /// numbers (`booking` or `expertDefault`). The estimated qualifier
    /// only shifts labels + adds a caption; the layout is identical so
    /// experts don't experience UI shift between the two branches.
    private func populatedCard(qualifier: NetQualifier?) -> some View {
        VStack(spacing: 12) {
            row(label: "Client pays", amount: breakdown?.grossAmount, tint: Brand.overlayWhite80)

            HStack {
                Text(feeLabel)
                    .font(.brand(.subheadline, weight: .regular))
                    .foregroundColor(Brand.overlayWhite80)
                Spacer()
                Text(signedFeeAmount)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.error)
            }

            Divider().background(Brand.overlayWhite20)

            HStack(alignment: .firstTextBaseline) {
                Text("You earn")
                    .font(.brand(.subheadline, weight: .bold))
                    .foregroundColor(Brand.onSurface)
                Spacer()
                Text(netAmountText(qualifier: qualifier))
                    .font(.brand(.title2, weight: .bold))
                    .foregroundColor(Brand.primary)
            }

            if let qualifier {
                HStack {
                    Text(qualifier.caption)
                        .font(.brand(.caption, weight: .regular))
                        .foregroundColor(Brand.overlayWhite60)
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.primary.opacity(0.12))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Brand.primary.opacity(0.28), lineWidth: 1))
        )
    }

    // MARK: - Pending card (unavailable / nil breakdown)

    /// No commission rate resolvable — show the session price + a
    /// "pending" caption. Deliberately does NOT put a dollar figure
    /// under a "you earn" label; the spec forbids it because it
    /// silently overstates the payout.
    private var pendingCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Session price")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(Brand.overlayWhite80)
                Spacer()
                Text(sessionPriceText)
                    .font(.brand(.title3, weight: .bold))
                    .foregroundColor(Brand.onSurface)
            }
            HStack(spacing: 6) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption.weight(.regular))
                    .foregroundColor(Brand.overlayWhite60)
                Text("Payout amount pending")
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(Brand.overlayWhite60)
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.overlayWhite05)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Brand.overlayWhite20, lineWidth: 1))
        )
    }

    // MARK: - Row helpers

    private func row(label: String, amount: Double?, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(tint)
            Spacer()
            Text(formatted(amount))
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
        }
    }

    // MARK: - Derived labels

    /// Includes the percent when we have it — "Platform fee (15%)" reads
    /// better than a bare "Platform fee" and matches the spec mock.
    /// Suppresses the parenthetical for legitimately-zero commissions
    /// (which are real, per §3) since "(0%)" is noisy.
    private var feeLabel: String {
        guard let pct = breakdown?.commissionPct, pct > 0 else {
            return "Platform fee"
        }
        let pctString: String
        if pct.truncatingRemainder(dividingBy: 1) == 0 {
            pctString = String(format: "%.0f", pct)
        } else {
            pctString = String(format: "%.1f", pct)
        }
        return "Platform fee (\(pctString)%)"
    }

    /// The fee row renders with a leading minus so it reads as a
    /// subtraction. Falls through to a plain formatter for the nil case
    /// (shouldn't hit this branch — populatedCard only runs when
    /// feeSource is `.booking` / `.expertDefault`, both of which
    /// populate `platformFee`).
    private var signedFeeAmount: String {
        guard let fee = breakdown?.platformFee else { return "—" }
        return "−" + formatted(fee)
    }

    /// `qualifier == .estimated` prefixes the value with `≈` so the
    /// user reads the number as approximate. The trailing caption is
    /// what carries the "estimated" word.
    private func netAmountText(qualifier: NetQualifier?) -> String {
        let raw = formatted(breakdown?.netAmount)
        return qualifier == .estimated ? "≈ " + raw : raw
    }

    private var sessionPriceText: String {
        let amount = breakdown?.grossAmount ?? fallbackGross
        return formatted(amount, currencyOverride: breakdown?.currency ?? fallbackCurrency)
    }

    // MARK: - Money formatting

    /// Formats `amount` in the breakdown's currency (or the caller's
    /// fallback for the `unavailable` path). Drives fraction-digit
    /// behavior off `NumberFormatter.currency` so zero-decimal
    /// currencies (JPY, KRW, VND, CLP, ISK, XOF, XAF — already scaled
    /// server-side per the spec) render without a decimal, and the
    /// currency symbol matches the ISO code rather than being
    /// hard-coded to `$`.
    ///
    /// Compares against `nil` explicitly rather than coalescing so a
    /// legitimate zero (0% commission → `platformFee: 0`) still renders
    /// as `$0.00` instead of being treated as missing.
    private func formatted(_ amount: Double?, currencyOverride: String? = nil) -> String {
        guard let amount else { return "—" }
        let code = currencyOverride ?? breakdown?.currency ?? fallbackCurrency
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.string(from: NSNumber(value: amount))
            ?? String(format: "%@ %.2f", code, amount)
    }

    // MARK: - Types

    /// Qualifier applied to the net amount when the fee was derived
    /// from the expert's default rate rather than locked to this
    /// booking — the number is projected, not final.
    private enum NetQualifier {
        case estimated

        var caption: String {
            switch self {
            case .estimated:
                return "Estimated — fee applies when the booking is charged."
            }
        }
    }
}
