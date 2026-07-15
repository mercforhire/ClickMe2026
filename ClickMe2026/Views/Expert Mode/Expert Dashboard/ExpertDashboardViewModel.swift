//
//  ExpertDashboardViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class ExpertDashboardViewModel {
    // MARK: Data

    var expertFirstName: String
    var expertLastName: String
    var avatarURL: String
    var pendingCount: Int
    var sessionName: String
    var sessionTopic: String
    var sessionTime: String
    var isStartingNow: Bool
    var weekEarnings: String
    var availablePayout: String
    var nextPayoutDate: String

    // MARK: Actions

    var onAvatarTap: () -> Void
    var onPendingRequests: () -> Void
    var onViewCalendar: () -> Void
    var onJoinSession: () -> Void
    var onWithdraw: () -> Void
    var onAvailability: () -> Void
    var onEditTopics: () -> Void
    var onPayouts: () -> Void
    var onProfileSettings: () -> Void

    // MARK: Init

    init(
        expertFirstName: String = "Ethan",
        expertLastName: String = "Carter",
        avatarURL: String = "https://randomuser.me/api/portraits/men/32.jpg",
        pendingCount: Int = 3,
        sessionName: String = "Sophia Miller",
        sessionTopic: String = "Marketing Strategy",
        sessionTime: String = "10:00 AM — 11:00 AM",
        isStartingNow: Bool = true,
        weekEarnings: String = "$1,420",
        availablePayout: String = "$3,850",
        nextPayoutDate: String = "May 15",
        onAvatarTap: @escaping () -> Void = {},
        onPendingRequests: @escaping () -> Void = {},
        onViewCalendar: @escaping () -> Void = {},
        onJoinSession: @escaping () -> Void = {},
        onWithdraw: @escaping () -> Void = {},
        onAvailability: @escaping () -> Void = {},
        onEditTopics: @escaping () -> Void = {},
        onPayouts: @escaping () -> Void = {},
        onProfileSettings: @escaping () -> Void = {}
    ) {
        self.expertFirstName = expertFirstName
        self.expertLastName = expertLastName
        self.avatarURL = avatarURL
        self.pendingCount = pendingCount
        self.sessionName = sessionName
        self.sessionTopic = sessionTopic
        self.sessionTime = sessionTime
        self.isStartingNow = isStartingNow
        self.weekEarnings = weekEarnings
        self.availablePayout = availablePayout
        self.nextPayoutDate = nextPayoutDate
        self.onAvatarTap = onAvatarTap
        self.onPendingRequests = onPendingRequests
        self.onViewCalendar = onViewCalendar
        self.onJoinSession = onJoinSession
        self.onWithdraw = onWithdraw
        self.onAvailability = onAvailability
        self.onEditTopics = onEditTopics
        self.onPayouts = onPayouts
        self.onProfileSettings = onProfileSettings
    }
}
