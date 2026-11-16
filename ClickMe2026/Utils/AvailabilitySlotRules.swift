//
//  AvailabilitySlotRules.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Availability slot rules

/// The picker rows and the Add-hours rule for an availability time range
/// (EXP-05 to EXP-07, D-06 to D-08).
///
/// All times are minutes from midnight. The helper takes and returns plain
/// `Int`s, so the rules are testable without a view or a view model.
enum AvailabilitySlotRules {

    /// Spacing of the picker grid, in minutes.
    static let gridStep = 30

    /// The last time the picker offers as a new choice, 23:30 (D-06). The
    /// picker never offers 24:00 (12:00 AM) as a new End choice.
    static let lastGridTime = 23 * 60 + 30

    /// The rows for the Start or End list of the time-range sheet.
    ///
    /// The rows are the 30-minute grid from 00:00 to `lastGridTime`, kept when
    /// earlier than the draft end (Start list) or later than the draft start
    /// (End list). `storedValue` joins the list when it passes the same test,
    /// so a stored off-grid time (09:15) or a stored 24:00 end shows as a
    /// normal selected row, in time order, with its exact value (EXP-07,
    /// D-08). The rows are strictly ascending with no duplicate.
    ///
    /// - Parameters:
    ///   - isStart: `true` for the Start list, `false` for the End list.
    ///   - draftStart: The start of the draft the expert is editing.
    ///   - draftEnd: The end of the draft the expert is editing.
    ///   - storedValue: The slot's start (Start list) or end (End list) as the
    ///     sheet opened. Because the sheet passes the value from when it
    ///     opened, an off-grid or 24:00 time stays a row for as long as the
    ///     sheet is open, even after the expert taps another row.
    static func pickerRows(isStart: Bool, draftStart: Int, draftEnd: Int, storedValue: Int) -> [Int] {
        let grid = Array(stride(from: 0, through: lastGridTime, by: gridStep))
        let allowed: (Int) -> Bool = { isStart ? $0 < draftEnd : $0 > draftStart }
        var rows = grid.filter(allowed)
        if allowed(storedValue) { rows.append(storedValue) }
        return Array(Set(rows)).sorted()
    }

    /// The slot Add hours appends, or `nil` when the day has no room left.
    ///
    /// With no slots (`latestEnd` is `nil`) the new slot is 9:00 AM to 5:00 PM,
    /// the same as enabling an empty day. Otherwise it starts 30 minutes after
    /// the latest end across all slots, runs 60 minutes and clamps its end to
    /// `lastGridTime` (D-06, D-07). It returns `nil` when that start would be
    /// 23:00 or later, which is the user decision of 2026-11-16 (UI U3):
    /// "the start is already 23:00 or later" means the new slot's start, not
    /// the latest end. A 23:00 to 23:30 slot can still be made by editing one.
    ///
    /// - Parameter latestEnd: The largest end across the day's slots, or `nil`
    ///   when the day has none. Never the last array item: the expert may have
    ///   edited an earlier slot to run later.
    static func addHours(after latestEnd: Int?) -> AvailabilityTimeSlot? {
        guard let latestEnd else {
            return AvailabilityTimeSlot(start: 9 * 60, end: 17 * 60)
        }
        let start = latestEnd + gridStep
        guard start < 23 * 60 else { return nil }
        return AvailabilityTimeSlot(start: start, end: min(start + 60, lastGridTime))
    }
}
