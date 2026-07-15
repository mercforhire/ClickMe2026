//
//  LoadState.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
}
