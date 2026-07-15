//
//  ClientBookingDetail.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Full detail for a single booking from `GET /client/bookings/:id`.
/// Superset of `ClientBookingItem` — includes topic pricing, expert title,
/// expert timezone, payment status, join link, and the client's own note.
struct ClientBookingDetail: Decodable {

    struct Topic: Decodable {
        struct Price: Decodable {
            let amount: Int?
            let currency: String?
        }
        let id: UUID
        let title: String
        let durationMins: Int?
        /// Observed at the topic level (sibling of `price`), not inside it.
        let isFree: Bool
        let price: Price?
    }

    struct Expert: Decodable {
        let id: UUID
        let fullName: String?
        let avatarUrl: String?
        let title: String?
    }

    let bookingId: UUID
    /// Raw booking status enum value ("confirmed", "pending_approval", …).
    let status: String
    let startTime: Date
    let endTime: Date
    let meetingType: MeetingType
    /// Expert's IANA timezone identifier (e.g. "America/Sao_Paulo").
    let expertTimezone: String?
    /// Server-driven payment status: `held / captured / refunded / none`.
    /// Free topics report `none`.
    let paymentStatus: String
    let topic: Topic
    let expert: Expert
    /// External meeting URL (Skype/Zoom) or in-app deep link. `nil` when
    /// there's nothing to link to yet.
    let joinLink: String?
    /// Note the client attached at booking time. `nil` when absent.
    let clientNotes: String?
}
