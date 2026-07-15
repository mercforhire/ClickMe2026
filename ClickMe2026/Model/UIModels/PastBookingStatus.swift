//
//  PastBookingStatus.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Compressed UI representation of a past booking's outcome. The wire enum
/// `BookingStatus` has five past cases; this UI enum collapses them into
/// the three the design shows: `declined → .cancelled`, `expired → .missed`.
enum PastBookingStatus: Hashable {
    case completed, cancelled, missed

    var label: String {
        switch self {
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .missed:    return "Missed"
        }
    }

    var color: Color {
        switch self {
        case .completed: return Brand.primary
        case .cancelled: return Color(red: 1.000, green: 0.420, blue: 0.420)
        case .missed:    return Color(red: 1.000, green: 0.720, blue: 0.300)
        }
    }
}
