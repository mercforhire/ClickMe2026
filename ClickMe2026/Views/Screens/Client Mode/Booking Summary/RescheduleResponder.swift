//
//  RescheduleResponder.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation

/// Shared accept / decline logic for a client answering an expert-proposed
/// reschedule (BOOK-06, D-01).
///
/// Lifted from `BookingSummaryViewModel` so the money-affecting path exists once
/// and both screens that show the response card use it. The owner supplies
/// `refetch`, which is called after a successful accept or decline so the screen
/// updates in place (D-03).
///
/// Observable rather than `ObservableObject`: it is owned by view models that
/// are themselves `ObservableObject`s, and Observation tracks reads of
/// `isSubmitting` / `apiError` in a view body without forwarding
/// `objectWillChange`.
@MainActor
@Observable
final class RescheduleResponder {

    // MARK: Limits

    /// Server cap on the decline reason, counted in UTF-16 code units.
    static let declineReasonLimit = 500

    // MARK: Identity

    /// Server booking UUID. `nil` in the preview-seed path, where every action is a no-op.
    let bookingId: UUID?

    // MARK: State

    /// True while an accept or decline request is in flight. Both buttons read it,
    /// and a second call while it is set sends no second request.
    private(set) var isSubmitting = false

    /// User-facing text of the last failed accept or decline. Bound to the
    /// "Couldn't update booking" alert; the owner of the screen clears it on dismiss.
    var apiError: String?

    /// Called after a successful accept or decline. The owner's silent refresh,
    /// so the card disappears and the times update without a loading spinner.
    @ObservationIgnored var refetch: (@MainActor () async -> Void)?

    // MARK: Dependencies

    @ObservationIgnored private let api: ClickMeAPI
    @ObservationIgnored private let toasts: ToastCenter

    // MARK: Init

    /// - Parameters:
    ///   - bookingId: Server booking UUID, or `nil` in the preview-seed path.
    ///   - api: The API client; tests inject a stubbed one.
    ///   - toasts: Where the confirmation is posted; tests inject a fresh instance
    ///     so they never touch the shell's.
    init(bookingId: UUID?, api: ClickMeAPI = .shared, toasts: ToastCenter = .shared) {
        self.bookingId = bookingId
        self.api = api
        self.toasts = toasts
    }

    // MARK: - Accept

    /// Accept an expert-initiated reschedule. The booking rolls forward
    /// server-side, then `refetch` runs so the card clears and the times update.
    /// No-op when there's no booking id (preview seed) or a submission is
    /// already in flight.
    ///
    /// **PAYMENT_METHOD_REQUIRED recovery (Phase 27.1):** the check on this
    /// endpoint is DB-only, so a 422 does not mean "user has no cards." Read the
    /// vault and retry once with a `stripe_payment_method_id` when possible. See
    /// `RESCHEDULE-PAYMENT-CONVERSION.md` §3.1.
    func accept() async {
        guard !isSubmitting, let bookingId else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await api.acceptClientReschedule(id: bookingId)
            // Only after a 2xx: a failed accept never confirms (T-03-11).
            toasts.show("Reschedule accepted")
            await refetch?()
            return
        } catch {
            if BookingErrorMapper.code(for: error) != .paymentMethodRequired {
                apiError = Self.acceptMessage(for: error)
                return
            }
            // Fall through to the saved-card recovery below.
        }

        let vault: [PaymentMethodItem]
        do {
            vault = try await api.getPaymentMethods().data.paymentMethods
        } catch {
            apiError = Self.vaultReadFailedMessage
            return
        }

        guard let paymentMethodId = vault.first(where: { $0.isDefault })?.id ?? vault.first?.id else {
            apiError = Self.noSavedCardMessage
            return
        }

        do {
            _ = try await api.acceptClientReschedule(id: bookingId, stripePaymentMethodId: paymentMethodId)
            toasts.show("Reschedule accepted")
            await refetch?()
        } catch {
            // The second failure is terminal, including a repeat
            // PAYMENT_METHOD_REQUIRED (the chosen card can't be prepared for
            // future billing either).
            if BookingErrorMapper.code(for: error) == .paymentMethodRequired {
                apiError = Self.unusableCardMessage
            } else {
                apiError = Self.acceptMessage(for: error)
            }
        }
    }

    // MARK: - Decline

    /// Decline an expert-initiated reschedule with an optional reason.
    ///
    /// The reason is trimmed, left out when blank, and capped at
    /// `declineReasonLimit` UTF-16 units without splitting a character, matching
    /// the server's `rescheduleDeclineSchema` (`z.string().max(500)`).
    /// - Parameter reason: Free text from the decline prompt. `nil` or blank sends no reason.
    func decline(reason: String?) async {
        guard !isSubmitting, let bookingId else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        let trimmed = reason?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let capped = UTF16Prefix.prefix(trimmed, limit: Self.declineReasonLimit)
        do {
            _ = try await api.declineClientReschedule(id: bookingId, reason: capped.isEmpty ? nil : capped)
            await refetch?()
        } catch {
            apiError = error.userMessage
        }
    }

    // MARK: - Error copy

    static let noSavedCardMessage =
        "Please add a payment method in Profile > Payment before accepting this reschedule."

    static let unusableCardMessage =
        "The card on file can't be used for this reschedule. Please add a new payment method in Profile > Payment and try again."

    static let vaultReadFailedMessage = "Couldn't check your saved payment methods. Please try again."

    static let outsideAuthWindowMessage =
        "This new time can't be covered by the payment hold on your booking. You can decline it, or cancel this booking and book again. Cancelling releases the hold on your card, so you won't be charged."

    /// Branches on `ErrorCode`, never on the message text.
    private static func acceptMessage(for error: Error) -> String {
        if BookingErrorMapper.code(for: error) == .rescheduleOutsideAuthWindow {
            return outsideAuthWindowMessage
        }
        return error.userMessage
    }

    // MARK: - Payment-conversion disclosure (Phase 27.1)

    /// True when accepting the pending reschedule would push the session past
    /// this booking's authorization window, in which case the server voids the
    /// current hold and schedules the charge for about 24 hours before the new
    /// session. See `RESCHEDULE-PAYMENT-CONVERSION.md` §3.1.
    /// - Parameters:
    ///   - proposal: The pending proposal, or `nil` when there is none.
    ///   - authorizationExpiresAt: End of the Stripe authorization window, or `nil` when no hold is live.
    static func requiresDisclosure(proposal: RescheduleProposal?, authorizationExpiresAt: Date?) -> Bool {
        guard let expiresAt = authorizationExpiresAt, let proposal else { return false }
        return proposal.proposedEnd > expiresAt
    }

    /// True when the T-24h charge would fire within the next ~24 hours (proposed
    /// start under 48 hours from `now`). Sub-24h proposals are refused
    /// server-side, so this only fires in the 24 to 48 hour band.
    /// - Parameters:
    ///   - proposal: The pending proposal, or `nil` when there is none.
    ///   - now: The reference time, injected so tests do not depend on the clock.
    static func chargesSoon(proposal: RescheduleProposal?, now: Date) -> Bool {
        guard let proposal else { return false }
        return proposal.proposedStart.timeIntervalSince(now) < 48 * 3600
    }

    /// Body of the "Accept the proposed reschedule?" dialog: the short text, the
    /// payment-conversion disclosure, or the disclosure plus the near-term caveat.
    /// - Parameters:
    ///   - proposal: The pending proposal.
    ///   - authorizationExpiresAt: End of the Stripe authorization window, or `nil`.
    ///   - now: The reference time for the near-term caveat.
    static func acceptDialogMessage(
        proposal: RescheduleProposal?,
        authorizationExpiresAt: Date?,
        now: Date
    ) -> String {
        let base = "The session will move to the new time the expert proposed."
        guard requiresDisclosure(proposal: proposal, authorizationExpiresAt: authorizationExpiresAt) else {
            return base
        }
        var text = base + "\n\nYour card hold will be released. Because the new time is more than a few days out, we'll release the current payment hold on your card and instead charge it automatically about 24 hours before your new session time. You won't be charged today."
        if chargesSoon(proposal: proposal, now: now) {
            text += "\n\nIf your new session is coming up soon, your card may be charged sooner than 24 hours from now."
        }
        return text
    }
}
