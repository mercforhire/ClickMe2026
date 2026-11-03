//
//  UserReportReason.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Enumerated reasons the server accepts for `POST /users/:id/report`
/// (and also for `POST /chats/:id/actions` with `action = "report"`).
/// See `docs/ios/USER-REPORTING.md` §1 and §2.
enum UserReportReason: String, CaseIterable, Identifiable, Codable {
    case harassment           = "harassment"
    case spam                 = "spam"
    case inappropriateContent = "inappropriate_content"
    case scamOrFraud          = "scam_or_fraud"
    case impersonation        = "impersonation"
    case other                = "other"

    var id: String { rawValue }

    /// User-facing label for the reason picker. Matches the "suggested
    /// display labels" column in the backend spec so admins and users
    /// see the same wording.
    var displayLabel: String {
        switch self {
        case .harassment:           return "Harassment or abuse"
        case .spam:                 return "Spam"
        case .inappropriateContent: return "Inappropriate content"
        case .scamOrFraud:          return "Scam or fraud"
        case .impersonation:        return "Impersonation"
        case .other:                return "Something else"
        }
    }
}
