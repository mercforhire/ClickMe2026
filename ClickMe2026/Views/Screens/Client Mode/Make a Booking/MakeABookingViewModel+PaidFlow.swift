//
//  MakeABookingViewModel+PaidFlow.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Confirm outcome unknown (PAY-02, D-03)

extension MakeABookingViewModel {

    /// An alert the paid flow raises while it stays on `.confirming`.
    enum PaidFlowAlert: Identifiable, Equatable {

        /// The automatic retries ran out and the server never said whether the
        /// booking exists. `paymentReference` is the PaymentIntent id (`pi_…`
        /// only, never the card id or a secret), shown so support can find the hold.
        case confirmUnknown(paymentReference: String?)

        /// The slot is taken, or the server reports a duplicate, for an expert and
        /// slot the client may already hold through an earlier confirm (D-04).
        /// Never shown as "slot taken": the booking may be the client's own.
        case mayAlreadyBeBooked

        var id: String {
            switch self {
            case .confirmUnknown: "confirmUnknown"
            case .mayAlreadyBeBooked: "mayAlreadyBeBooked"
            }
        }

        var title: String {
            switch self {
            case .confirmUnknown: "We couldn't confirm your booking"
            case .mayAlreadyBeBooked: "Couldn't book"
            }
        }

        var message: String {
            switch self {
            case let .confirmUnknown(paymentReference):
                let text = "Your request may already have been sent. Try again to check, "
                    + "or look in My Bookings before booking again."
                guard let paymentReference else { return text }
                return text + "\n\nPayment reference: \(paymentReference)"
            case .mayAlreadyBeBooked:
                return "You may already have this booking. Check My Bookings."
            }
        }
    }

    /// "Try again": runs the same confirm again with the same PaymentIntent and
    /// card, through the same bounded cycle (one attempt plus the automatic
    /// retries). A no-op unless a confirm is waiting on the client, so neither
    /// Book Now nor a second tap can start a second confirm (Pitfall 11).
    func retryConfirm() async {
        guard let paymentMethodId = confirmPaymentMethodId,
              paidStep == .confirming,
              !isConfirmRunning
        else { return }
        paidFlowAlert = nil
        await completePaidBooking(paymentMethodId: paymentMethodId)
    }

    /// "Not now": the client leaves the unknown outcome. Resets the paid flow
    /// silently, like a cancelled payment sheet: the form stays as it was and
    /// Book Now is enabled again.
    func dismissConfirmAlert() {
        paidFlowAlert = nil
        confirmPaymentMethodId = nil
        resetPaidFlow()
    }

    /// Closes the "Couldn't book" alert. The paid flow was already reset when the
    /// alert was raised, so this only clears the alert.
    func dismissMayAlreadyBeBookedAlert() {
        paidFlowAlert = nil
    }

    /// True while a paid confirm or one of its automatic retries runs and no
    /// alert is up. Drives the "Confirming your booking…" line (UI-SPEC L2).
    var showsConfirmingStatus: Bool {
        paidStep == .confirming && paidFlowAlert == nil
    }

    // MARK: - Payment sheet and 3DS entry points

    /// Called when the user dismisses the PaymentSheet without paying.
    func cancelPaidBooking() {
        resetPaidFlow()
    }

    /// Called by the SCA challenge sheet after 3DS finishes. Re-hits
    /// `/bookings/confirm` with the SAME `pm_…` — server sees the PI is
    /// now `requires_capture` and skips its own confirm, just creating
    /// the booking.
    func retryConfirmAfterSCA(paymentMethodId: String) async {
        pendingSCAChallenge = nil
        await completePaidBooking(paymentMethodId: paymentMethodId)
    }

    /// Called if the SCA challenge failed or the user cancelled it.
    func cancelSCA(withMessage message: String? = nil) {
        pendingSCAChallenge = nil
        if let message { bookingError = message }
        resetPaidFlow()
    }
}
