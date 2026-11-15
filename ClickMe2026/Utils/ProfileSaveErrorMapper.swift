//
//  ProfileSaveErrorMapper.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// The "Couldn't save changes" text for a failed Profile Settings save, shared
/// by the client and the expert view models (G-05-6).
///
/// A `422 VALIDATION_ERROR` names the fields to check, using the on-screen
/// labels in screen order. It never shows the server's field paths or raw
/// validation text (for example "Too small: ..."). Every other error, and a 422
/// with no field this table knows, falls back to `Error.userMessage`.
enum ProfileSaveErrorMapper {

    /// Backend field path to on-screen label, in screen order. A path matches a
    /// key when it equals it or continues it after a dot, so array items such as
    /// `languages.language_ids.0` fall under `languages`.
    private static let labelTable: [(key: String, label: String)] = [
        ("basic.first_name", "First Name"),
        ("basic.last_name", "Last Name"),
        ("basic.bio", "Bio"),
        ("professional.job_title", "Job Title"),
        ("professional.company", "Company"),
        ("location.city", "City"),
        ("location.state_province", "State/Province"),
        ("location.country_code", "Country"),
        ("languages", "Spoken Languages")
    ]

    /// The text for a caught save error.
    static func message(for error: Error) -> String {
        let fields = error.validationFieldErrors.map(\.field)
        let labels = labelTable
            .filter { entry in
                fields.contains { $0 == entry.key || $0.hasPrefix(entry.key + ".") }
            }
            .map(\.label)
        guard !labels.isEmpty else { return error.userMessage }
        return "Check \(joined(labels)), then try again."
    }

    /// "A", "A and B", "A, B and C".
    private static func joined(_ labels: [String]) -> String {
        guard let last = labels.last, labels.count > 1 else { return labels.first ?? "" }
        return labels.dropLast().joined(separator: ", ") + " and " + last
    }
}
