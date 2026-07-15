//
//  UpcomingBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class UpcomingBookingsViewModel {
    // MARK: Data

    var sessions: [UpcomingSession]

    // MARK: Actions

    var onJoinSession: (UpcomingSession) -> Void
    var onMessage: (UpcomingSession) -> Void
    var onReschedule: (UpcomingSession) -> Void
    var onEarningsDash: () -> Void
    var onAddSession: () -> Void
    var onUpdateAvailability: () -> Void
    var onViewPastHistory: () -> Void

    // MARK: Init

    init(
        sessions: [UpcomingSession] = UpcomingSession.samples,
        onJoinSession: @escaping (UpcomingSession) -> Void = { _ in },
        onMessage: @escaping (UpcomingSession) -> Void = { _ in },
        onReschedule: @escaping (UpcomingSession) -> Void = { _ in },
        onEarningsDash: @escaping () -> Void = {},
        onAddSession: @escaping () -> Void = {},
        onUpdateAvailability: @escaping () -> Void = {},
        onViewPastHistory: @escaping () -> Void = {}
    ) {
        self.sessions = sessions
        self.onJoinSession = onJoinSession
        self.onMessage = onMessage
        self.onReschedule = onReschedule
        self.onEarningsDash = onEarningsDash
        self.onAddSession = onAddSession
        self.onUpdateAvailability = onUpdateAvailability
        self.onViewPastHistory = onViewPastHistory
    }
}
