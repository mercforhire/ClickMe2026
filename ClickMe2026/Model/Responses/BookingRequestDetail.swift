//
//  BookingRequestDetail.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full booking request detail returned by `GET /expert/booking-requests/{id}`.
///
/// x-discrepancy #16: `session.meeting_type` is the raw DB enum (`in_app_voice` /
/// `skype_zoom`), not a humanized display string. Mobile UI must handle the real
/// enum values.
struct BookingRequestDetail: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct Session: Decodable {
        let startTime: Date
        let endTime: Date
        let topic: String?
        let meetingType: MeetingType
        /// `client_notes` field from the bookings row.
        let clientMessage: String?
    }

    struct Economics: Decodable {
        let potentialEarnings: Double?
        let currency: String?
    }

    let requestId: UUID
    let client: Client
    let session: Session
    let economics: Economics
}
