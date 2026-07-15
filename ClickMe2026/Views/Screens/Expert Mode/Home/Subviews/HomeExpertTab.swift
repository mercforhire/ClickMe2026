//
//  HomeExpertTab.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-02.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

// MARK: - Tab identity

enum HomeExpertTab: Int, CaseIterable, Hashable {
    case dashboard, bookings, topics, profile

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .bookings: return "Bookings"
        case .topics: return "Topics"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house"
        case .bookings: return "calendar"
        case .topics: return "pencil.and.list.clipboard"
        case .profile: return "person.circle"
        }
    }
}
