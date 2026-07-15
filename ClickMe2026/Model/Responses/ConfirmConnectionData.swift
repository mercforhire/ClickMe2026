//
//  ConfirmConnectionData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Result of confirming the call connection — booking transitions to `inProgress`.
struct ConfirmConnectionData: Decodable {
    let bookingId: UUID
    let status: BookingStatus
    let connectionStatus: String?
    let method: String?
}
