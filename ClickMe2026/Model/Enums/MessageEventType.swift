//
//  MessageEventType.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Booking lifecycle event type — only set on `messages` rows where `type == .event`.
enum MessageEventType: String, Decodable {
    case bookingRequest      = "booking_request"
    case bookingConfirmed    = "BOOKING_CONFIRMED"
    case bookingDeclined     = "BOOKING_DECLINED"
    case bookingCancelled    = "BOOKING_CANCELLED"
    case bookingRescheduled  = "BOOKING_RESCHEDULED"
    case bookingCompleted    = "BOOKING_COMPLETED"
    case bookingExpired      = "BOOKING_EXPIRED"
}
