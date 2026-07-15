//
//  BookingStatusMeta.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Booking status with display metadata for UI badge rendering.
struct BookingStatusMeta: Decodable {
    let label: String
    let code: BookingStatus
    let colorAccent: String
}
