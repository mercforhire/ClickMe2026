//
//  DateUtil.swift
//  ClickMe
//
//  Created by Leon Chen on 2021-04-06.
//  Rewritten 2026-06-21.
//

import Foundation

enum DateUtil {

    // MARK: - Format catalog

    enum Format: String, CaseIterable, Sendable {
        /// `10/18/2021 5:30 PM`
        case usSlashDateTime12h     = "MM/dd/yyyy h:mm a"
        /// `2021-10-18T14:20:00`
        case iso8601Local           = "yyyy-MM-dd'T'HH:mm:ss"
        /// `Oct 18, 2021 3:45 PM`
        case shortMonthDateTime12h  = "MMM dd, yyyy h:mm a"
        /// `2021-10-18T14:25:00+0000`
        case iso8601Offset          = "yyyy-MM-dd'T'HH:mm:ssZ"
        /// `October 18, 2019`
        case longMonthDayYear       = "MMMM d, yyyy"
        /// `2021-10-18 13:30:45`
        case spaceDateTime          = "yyyy-MM-dd HH:mm:ss"
        /// `2021-10-18T03:15:13.2345+0000`
        case iso8601FractionalOffset = "yyyy-MM-dd'T'HH:mm:ss.SSSSZ"
        /// `1:12 PM`
        case time12h                = "h:mm a"
        /// `Tuesday October 18, 2021`
        case weekdayLongMonthDayYear = "EEEE MMMM d, yyyy"
        /// `October 18 5:30 PM`
        case longMonthDayTime12h    = "MMMM d h:mm a"
        /// `October 18`
        case longMonthDay           = "MMMM d"
        /// `10/18/2021`
        case usSlashDate            = "MM/dd/yyyy"
        /// `October, 2019`
        case longMonthYear          = "MMMM, yyyy"
        /// `Tue Oct 18`
        case shortWeekdayMonthDay   = "EE MMM d"
        /// `Oct 18`
        case shortMonthDay          = "MMM d"
        /// `Oct 18, 2021`
        case shortMonthDayYear      = "MMM d, yyyy"
    }

    // MARK: - Public API

    /// Renders `date` using `format` in the given time zone and locale.
    static func string(
        from date: Date,
        format: Format,
        timeZone: TimeZone = .current,
        locale: Locale = .enUSPOSIX
    ) -> String {
        formatter(format: format, timeZone: timeZone, locale: locale).string(from: date)
    }

    /// Parses `string` using `format`. Returns `nil` when the input doesn't match.
    static func date(
        from string: String,
        format: Format,
        timeZone: TimeZone = .utc,
        locale: Locale = .enUSPOSIX
    ) -> Date? {
        formatter(format: format, timeZone: timeZone, locale: locale).date(from: string)
    }

    /// Parses `input` in `inputFormat` / `inputTimeZone` and re-renders it as
    /// `outputFormat` / `outputTimeZone`.
    static func convert(
        _ input: String,
        from inputFormat: Format,
        to outputFormat: Format,
        inputTimeZone: TimeZone = .utc,
        outputTimeZone: TimeZone = .current,
        locale: Locale = .enUSPOSIX
    ) -> String? {
        guard let parsed = date(from: input, format: inputFormat, timeZone: inputTimeZone, locale: locale) else {
            return nil
        }
        return string(from: parsed, format: outputFormat, timeZone: outputTimeZone, locale: locale)
    }

    // MARK: - Locale-aware time

    /// The time of day in the device's own style: `2:00 PM` on a 12-hour
    /// device, `14:00` on a 24-hour one (BOOK-04).
    ///
    /// The formatter is cached under the zone, the locale and the locale's
    /// resolved hour pattern. The device's 12/24-hour setting does not change
    /// the locale identifier, so the hour pattern is part of the key: toggling
    /// the setting builds a new formatter instead of reusing a stale one
    /// (RESEARCH Pattern 7). Never `Date.FormatStyle`: its en_GB output differs
    /// in the leading zero (Pitfall 10).
    static func shortTime(
        _ date: Date,
        timeZone: TimeZone = .current,
        locale: Locale = .current
    ) -> String {
        let hourPattern = DateFormatter.dateFormat(fromTemplate: "j", options: 0, locale: locale) ?? ""
        let key = "short|\(timeZone.identifier)|\(locale.identifier)|\(hourPattern)"
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cache[key] {
            return cached.string(from: date)
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        formatter.timeZone = timeZone
        formatter.locale = locale
        cache[key] = formatter
        return formatter.string(from: date)
    }

    /// Trims `raw`; nil when it is nil, empty or only whitespace.
    static func normalizedZoneName(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    /// The zone's readable generic name (for example `Eastern Time`), or nil
    /// when the device has none. Never the raw IANA identifier.
    static func zoneName(for timeZone: TimeZone = .current, locale: Locale = .current) -> String? {
        normalizedZoneName(timeZone.localizedName(for: .generic, locale: locale))
    }

    // MARK: - Formatter cache

    private static let cacheLock = NSLock()
    nonisolated(unsafe) private static var cache: [String: DateFormatter] = [:]

    private static func formatter(format: Format, timeZone: TimeZone, locale: Locale) -> DateFormatter {
        let key = "\(format.rawValue)|\(timeZone.identifier)|\(locale.identifier)"
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = cache[key] {
            return cached
        }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = format.rawValue
        formatter.timeZone = timeZone
        formatter.locale = locale
        cache[key] = formatter
        return formatter
    }
}

// MARK: - Convenience constants

extension Locale {
    /// Locale recommended by Apple for fixed-format date parsing.
    static let enUSPOSIX = Locale(identifier: "en_US_POSIX")
}

extension TimeZone {
    static let utc = TimeZone(secondsFromGMT: 0) ?? .gmt
}
