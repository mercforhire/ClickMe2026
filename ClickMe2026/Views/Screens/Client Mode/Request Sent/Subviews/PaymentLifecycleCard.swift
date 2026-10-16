//
//  PaymentLifecycleCard.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// A three-step timeline explaining the Phase 27 payment lifecycle to
/// the client: hold placed at booking → session runs → captured after
/// the session ends. Rendered in two places:
///
///  * `BookingRequestSentView` — post-payment, with `.holdPlaced` as
///    the current step so the checkmark on step 1 reinforces the
///    "your card was authorized, no charge yet" state.
///  * `PaymentInfoSheet` (pre-payment) — in `.upcoming` state so nothing
///    has happened yet; used to set expectations before the user taps
///    "Book Now".
///
/// Deliberately silent on platform fees / commissions per product
/// direction ("client pays exactly what the session cost is" — no fee
/// is layered onto the client's charge). The copy answers "when am I
/// charged?", not "how much of my money goes where?".
struct PaymentLifecycleCard: View {

    /// Which step should render as the current one (green tint, filled
    /// icon). Steps before it render as "done" (still green, but with
    /// a checkmark); steps after render as "future" (muted).
    enum CurrentStep {
        /// Pre-payment — nothing has happened yet.
        case upcoming
        /// Post-payment — step 1 (hold placed) is done.
        case holdPlaced
    }

    let currentStep: CurrentStep

    /// Optional session date/time label — when provided, replaces the
    /// generic "Your session runs" copy on step 2 with the actual
    /// scheduled time. Only used in the post-payment context where we
    /// have the concrete booking loaded.
    let sessionWhen: String?

    init(currentStep: CurrentStep, sessionWhen: String? = nil) {
        self.currentStep = currentStep
        self.sessionWhen = sessionWhen
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("What happens next")
                .font(.brand(.subheadline, weight: .bold))
                .foregroundColor(Brand.onSurface)
                .padding(.bottom, 14)

            stepRow(
                index: 0,
                title: "A hold is placed on your card",
                subtitle: "No charge yet — funds are just reserved.",
                icon: "lock.fill"
            )

            connector(above: 1)

            stepRow(
                index: 1,
                title: step2Title,
                subtitle: "You can join the call from My Bookings.",
                icon: "calendar"
            )

            connector(above: 2)

            stepRow(
                index: 2,
                title: "Your card is charged after the session",
                subtitle: "Usually within 15 minutes of the session ending.",
                icon: "checkmark.seal.fill"
            )
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.overlayWhite05)
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Brand.overlayWhite20, lineWidth: 1))
        )
    }

    // MARK: - Row

    private func stepRow(index: Int, title: String, subtitle: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge(index: index, systemName: icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(titleColor(index: index))
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.brand(.caption, weight: .regular))
                    .foregroundColor(Brand.overlayWhite60)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }

    /// Vertical connector line between step badges. Colored green up to
    /// (and including) the current step, muted after.
    private func connector(above stepIndex: Int) -> some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(connectorColor(above: stepIndex))
                .frame(width: 2, height: 14)
                .padding(.leading, 13) // centers under the 28pt badge
            Spacer()
        }
    }

    // MARK: - Icon badge

    private func iconBadge(index: Int, systemName: String) -> some View {
        let done = index < currentStepIndex
        let current = index == currentStepIndex
        let tint: Color = (done || current) ? Brand.primary : Brand.overlayWhite60
        let fill: Color = (done || current) ? Brand.primary.opacity(0.18) : Brand.overlayWhite10

        return ZStack {
            Circle().fill(fill).frame(width: 28, height: 28)
            Image(systemName: done ? "checkmark" : systemName)
                .font(.caption.weight(.bold))
                .foregroundColor(tint)
        }
    }

    // MARK: - Derived

    /// Index of the current step. `.upcoming` = nothing done yet
    /// (`-1` so step 0 renders as "future" until the user actually
    /// pays). `.holdPlaced` = step 0 done, step 1 is next.
    private var currentStepIndex: Int {
        switch currentStep {
        case .upcoming:   return -1
        case .holdPlaced: return 0
        }
    }

    private var step2Title: String {
        if let when = sessionWhen, !when.isEmpty {
            return "Your session runs on \(when)"
        }
        return "Your session runs at the scheduled time"
    }

    private func titleColor(index: Int) -> Color {
        index <= currentStepIndex ? Brand.onSurface : Brand.onSurface
    }

    private func connectorColor(above stepIndex: Int) -> Color {
        stepIndex <= currentStepIndex ? Brand.primary.opacity(0.35) : Brand.overlayWhite10
    }
}

// MARK: - Previews

#Preview("Upcoming (pre-payment)") {
    ZStack {
        Brand.surface.ignoresSafeArea()
        PaymentLifecycleCard(currentStep: .upcoming)
            .padding(20)
    }
    .preferredColorScheme(.dark)
}

#Preview("Hold placed (post-payment)") {
    ZStack {
        Brand.surface.ignoresSafeArea()
        PaymentLifecycleCard(
            currentStep: .holdPlaced,
            sessionWhen: "Aug 15, 2:00 PM"
        )
        .padding(20)
    }
    .preferredColorScheme(.dark)
}
