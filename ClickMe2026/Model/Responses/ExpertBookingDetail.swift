//
//  ExpertBookingDetail.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full detail returned by `GET /expert/bookings/{id}/details`.
///
/// x-discrepancy #5: `client.headline`, `client.rating`, `client.review_count`,
/// `session.schedule.date`/`date_label`/`time_range`/`timezone`, and a `connection`
/// object from the API reference spec are NOT returned. `expert_private_note` is
/// never included.
struct ExpertBookingDetail: Decodable {
    struct Client: Decodable {
        let id: UUID
        let name: String?
        let avatarUrl: String?
    }

    struct Session: Decodable {
        struct ConsultationFee: Decodable {
            let amount: Double
            let currency: String
            let label: String
        }

        struct Schedule: Decodable {
            let startTime: Date
            let endTime: Date
        }

        let topicTitle: String?
        let consultationFee: ConsultationFee
        let schedule: Schedule
        let meetingType: MeetingType
    }

    struct PreparationNotes: Decodable {
        /// `client_notes` from the bookings row.
        let text: String?
    }

    struct Actions: Decodable {
        let canJoin: Bool
        let canReschedule: Bool
        let canCancel: Bool
        let canMessage: Bool
    }

    let bookingId: UUID
    let status: BookingStatusMeta
    let client: Client
    let session: Session
    let preparationNotes: PreparationNotes
    let actions: Actions
}
