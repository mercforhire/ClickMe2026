//
//  ConfirmBookingData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Result of a successful booking confirmation via Stripe authorization.
struct ConfirmBookingData: Decodable {
    let bookingId: UUID
    let status: BookingStatus
    let message: String
    let estimatedConfirmationTime: String
}
