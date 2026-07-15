//
//  EndCallData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Result of ending a call session.
struct EndCallData: Decodable {
    let bookingId: UUID
    let status: BookingStatus
    let actualDurationSecs: Int?
    let endReason: EndReason
    let reviewSeamTriggered: Bool
}
