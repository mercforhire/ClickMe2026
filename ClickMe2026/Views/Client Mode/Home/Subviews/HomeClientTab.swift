//
//  HomeClientTab.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

// MARK: - Tab identity

enum HomeClientTab: Int, CaseIterable, Hashable {
    case explore, bookings, chats, profile

    var title: String {
        switch self {
        case .explore: return "Explore"
        case .bookings: return "Bookings"
        case .chats: return "Chats"
        case .profile: return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .explore: return "magnifyingglass"
        case .bookings: return "calendar"
        case .chats: return "bubble.left.and.bubble.right"
        case .profile: return "person.circle"
        }
    }
}
