//
//  ExpertBookingItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Single booking row returned by `GET /expert/bookings`.
struct ExpertBookingItem: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct Session: Decodable {
        let topic: String?
        let startTime: Date
        let endTime: Date
        let meetingType: MeetingType
    }

    struct Actions: Decodable {
        /// True when now is within 5 minutes before start_time up to end_time.
        let canJoin: Bool
        let canReschedule: Bool
        let canMessage: Bool
    }

    let bookingId: UUID
    let client: Client
    let session: Session
    let status: BookingStatusMeta
    let actions: Actions
}
