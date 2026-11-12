//
//  MakeABookingViewModel+PaidAttempt.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Paid attempt snapshot (PAY-02, CR-01)

extension MakeABookingViewModel {

    /// What `POST /bookings/confirm` sends for one paid attempt, captured when
    /// the PaymentIntent is created. Every confirm of the attempt (the first
    /// call, the automatic retries, Try again and the 3DS retry) and the D-04
    /// ledger key read only this, so a later change on the form cannot change
    /// what is confirmed.
    ///
    /// The `pm_…` id is not part of it because the card is chosen later, in the
    /// sheet (`confirmPaymentMethodId`). Android keeps the same snapshot as
    /// `PaidContext`.
    struct PaidAttempt: Equatable {
        let topic: BookingTopic
        let slot: BookingTimeSlot
        let paymentIntentId: String
        let meetingType: MeetingType
        let clientNotes: String?
    }
}
