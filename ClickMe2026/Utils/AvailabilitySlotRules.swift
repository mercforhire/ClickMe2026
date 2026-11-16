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
}
