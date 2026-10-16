//
//  BookingNoteData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Private booking note — same shape for both roles. Backed by two
/// separate server endpoints:
/// - `/bookings/:id/note` (expert-only)
/// - `/client/bookings/:id/note` (client-only)
///
/// Each caller sees only their own note. `note` is nil when the caller
/// hasn't written one yet. Uniform-404 contract: non-owner callers
/// cannot distinguish not-found from not-owned.
struct BookingNoteData: Decodable {
    let bookingId: UUID
    let note: String?
}
