//
//  DeleteAccountReason.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Reason categories the client can send to `DELETE /user/account` as
/// `reason_category`. Human labels stay client-side so the server can group
/// on stable machine keys without breaking on copy tweaks.
enum DeleteAccountReason: String, CaseIterable, Identifiable, Hashable {
    case tooExpensive     = "too_expensive"
    case foundAlternative = "found_alternative"
    case privacyConcerns  = "privacy_concerns"
    case other            = "other"

    var id: String { rawValue }

    /// String sent to the server as `reason_category`.
    var wireKey: String { rawValue }

    /// String rendered in the reason list.
    var label: String {
        switch self {
        case .tooExpensive:     return "Too expensive"
        case .foundAlternative: return "Found an alternative"
        case .privacyConcerns:  return "Privacy concerns"
        case .other:            return "Other"
        }
    }
}
