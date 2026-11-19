//
//  LoadState.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Four-state life-cycle for view models that fetch remote data. Used by
/// almost every screen — idle → loading → (loaded | failed(message)).
///
/// The `.failed` case carries a pre-mapped, user-facing string rather than
/// the underlying `Error` so views can render it directly. Callers map via
/// the shared `NetworkError.userMessage` helper.
enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case failed(String)

    /// Where a section goes when the load that set it to `.loading` is cancelled,
    /// for example because the screen went away (IN-15). A cancelled load is not a
    /// failure, so the section returns to what it showed before (`previous`): its
    /// loaded content, or its failure with Retry. A section that was never loaded
    /// returns to `.idle`, and the screen's `.task` loads it again when it reappears.
    ///
    /// A section that is no longer `.loading` was settled by another load and stays.
    /// A `previous` of `.loading` belonged to an earlier load that nothing is running
    /// any more, so it returns to `.idle` as well.
    func afterCancelledLoad(previous: LoadState) -> LoadState {
        guard self == .loading else { return self }
        return previous == .loading ? .idle : previous
    }
}
