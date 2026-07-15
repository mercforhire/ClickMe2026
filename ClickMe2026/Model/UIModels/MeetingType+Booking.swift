//
//  MeetingType+Booking.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// UI helpers for the wire enum `MeetingType`. Kept in a separate file so
/// the pure wire enum in `Model/Enums/` stays free of display concerns.
extension MeetingType {
    /// Human-readable label used in the meeting-type picker.
    var displayName: String {
        switch self {
        case .inAppVoice: return "In-app Voice Call"
        case .skypeZoom:  return "Skype/Zoom Call"
        }
    }

    /// All cases, ordered for the picker.
    static var pickerCases: [MeetingType] { [.inAppVoice, .skypeZoom] }
}
