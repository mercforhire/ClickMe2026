//
//  Timezones.swift
//  ClickMe2026
//

import Foundation

enum Timezones {
    /// A timezone the user can pick. `id` is the IANA identifier we send
    /// to the server (`PUT /expert/availability` expects IANA); `label` is
    /// the human-readable form shown in the picker.
    struct Entry: Hashable, Identifiable {
        let id: String
        let label: String
    }

    static let all: [Entry] = [
        Entry(id: "Pacific/Midway",      label: "(GMT-11:00) Midway"),
        Entry(id: "America/Anchorage",   label: "(GMT-09:00) Alaska"),
        Entry(id: "America/Los_Angeles", label: "(GMT-08:00) Pacific Time"),
        Entry(id: "America/Denver",      label: "(GMT-07:00) Mountain Time"),
        Entry(id: "America/Chicago",     label: "(GMT-06:00) Central Time"),
        Entry(id: "America/New_York",    label: "(GMT-05:00) Eastern Time"),
        Entry(id: "UTC",                 label: "(GMT+00:00) UTC"),
        Entry(id: "Europe/London",       label: "(GMT+00:00) London"),
        Entry(id: "Europe/Paris",        label: "(GMT+01:00) Paris"),
        Entry(id: "Asia/Kolkata",        label: "(GMT+05:30) Mumbai"),
    ]

    /// Best-effort match of the device's current timezone to a bundled
    /// entry. Tries exact IANA identifier first, then falls back to GMT
    /// offset match, then to UTC.
    static func detected(from device: TimeZone = .current) -> Entry {
        if let match = all.first(where: { $0.id == device.identifier }) {
            return match
        }
        let deviceOffset = device.secondsFromGMT()
        return all.first { parseOffsetSeconds($0.label) == deviceOffset }
            ?? all.first { $0.id == "UTC" }
            ?? all[0]
    }

    /// Look up a bundled entry by IANA id (used to hydrate from a server
    /// response). Returns nil for zones we don't have a UI label for.
    static func entry(forId id: String) -> Entry? {
        all.first { $0.id == id }
    }

    private static func parseOffsetSeconds(_ label: String) -> Int? {
        guard let open = label.firstIndex(of: "("),
              let close = label.firstIndex(of: ")"),
              open < close else { return nil }
        let inside = label[label.index(after: open)..<close]
        guard inside.hasPrefix("GMT") else { return nil }
        let offset = inside.dropFirst(3)
        guard let sign = offset.first, sign == "+" || sign == "-" else { return 0 }
        let parts = offset.dropFirst().split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]) else { return nil }
        let magnitude = hours * 3600 + minutes * 60
        return sign == "-" ? -magnitude : magnitude
    }
}
