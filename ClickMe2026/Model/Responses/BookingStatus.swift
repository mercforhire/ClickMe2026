//
//  BookingStatus.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Canonical booking status enum. UPCOMING: `pendingApproval`, `confirmed`,
/// `pendingReschedule`, `inProgress`. PAST: `completed`, `cancelled`,
/// `declined`, `missed`, `expired`.
enum BookingStatus: String, Decodable {
    case pendingApproval    = "pending_approval"
    case confirmed
    case pendingReschedule  = "pending_reschedule"
    case inProgress         = "in_progress"
    case completed
    case cancelled
    case declined
    case missed
    case expired
}
