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
    case dashboard, bookings, topics, chats, profile

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .bookings: return "Bookings"
        case .topics: return "Topics"
        case .chats: return "Chats"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "house"
        case .bookings: return "calendar"
        case .topics: return "pencil.and.list.clipboard"
        case .chats: return "message"
        case .profile: return "person.circle"
        }
    }
}
