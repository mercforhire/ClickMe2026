//
//  Utils.swift
//  ClickMe
//
//  Created by Leon Chen on 2024-01-03.
//  Rewritten 2026-06-21.
//

import Foundation

enum Utils {

    /// Writes `data` to a file in the app's Documents directory, replacing any
    /// existing file at that location, and returns its URL.
    @discardableResult
    static func saveToDocuments(filename: String, data: Data) throws -> URL {
        let url = URL.documentsDirectory.appending(path: filename)
        try data.write(to: url, options: [.atomic])
        return url
    }

    /// Localized "time ago" string (e.g. "yesterday", "2 hours ago").
    static func timeAgo(since date: Date, locale: Locale = .autoupdatingCurrent) -> String {
        date.formatted(
            .relative(presentation: .named, unitsStyle: .wide)
                .locale(locale)
        )
    }
}
