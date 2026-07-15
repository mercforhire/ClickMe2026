//
//  BookingNoteData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert private booking note. `note` is nil when no note has been set.
/// Uniform-404 contract: non-expert callers cannot distinguish not-found from not-owned.
struct BookingNoteData: Decodable {
    let bookingId: UUID
    let note: String?
}
