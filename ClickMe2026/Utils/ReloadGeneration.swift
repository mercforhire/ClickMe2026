//
//  ReloadGeneration.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Generation token that lets only the most recently started refetch write a screen.
///
/// Every `booking.update` socket event and every pull-to-refresh starts its own
/// fetch, so two fetches can be in flight at once and their responses can land
/// out of order. Without a guard, an older response that lands last overwrites a
/// newer one and the screen shows stale data. Each fetch calls `begin()` before
/// its first `await` and checks `isCurrent(_:)` before writing data or load
/// state. A superseded fetch is not cancelled: it finishes its network call and
/// simply writes nothing.
///
/// "Newest" means most recently started: a request made later is served no
/// earlier than one made before it, so its snapshot is at least as new.
nonisolated struct ReloadGeneration {

    /// The token handed out by the latest `begin()`; 0 before any fetch starts.
    private(set) var current = 0

    /// Starts a new fetch and makes every earlier token stale.
    mutating func begin() -> Int {
        current += 1
        return current
    }

    /// True while no later fetch has started since `token` was issued.
    func isCurrent(_ token: Int) -> Bool {
        token == current
    }
}
