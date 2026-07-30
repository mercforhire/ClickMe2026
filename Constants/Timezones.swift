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
    /// entry. Tries exact IANA identifier first, then falls back to a
    /// DST-aware offset match against each bundled zone's *current*
    /// offset (so e.g. `America/Toronto` in summer maps to
    /// `America/New_York`, which is also EDT). Falls through to UTC.
    static func detected(from device: TimeZone = .current) -> Entry {
        if let match = all.first(where: { $0.id == device.identifier }) {
            return match
        }
        let deviceOffset = device.secondsFromGMT()
        if let match = all.first(where: {
            TimeZone(identifier: $0.id)?.secondsFromGMT() == deviceOffset
        }) {
            return match
        }
        return all.first { $0.id == "UTC" } ?? all[0]
    }

    /// Look up a bundled entry by IANA id (used to hydrate from a server
    /// response). Returns nil for zones we don't have a UI label for.
    static func entry(forId id: String) -> Entry? {
        all.first { $0.id == id }
    }
}
