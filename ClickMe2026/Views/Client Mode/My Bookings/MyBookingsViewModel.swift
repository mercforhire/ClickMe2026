//
//  MyBookingsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class MyBookingsViewModel: ObservableObject {

    // MARK: View state
    @Published var selectedTab: Int
    @Published var glowPulse: Bool

    // MARK: Data
    @Published var upcomingBookings: [UpcomingBooking]
    @Published var pastBookings: [PastBooking]

    init(
        selectedTab: Int = 0,
        glowPulse: Bool = false,
        upcomingBookings: [UpcomingBooking] = MyBookingsViewModel.sampleUpcoming,
        pastBookings: [PastBooking] = MyBookingsViewModel.samplePast
    ) {
        self.selectedTab = selectedTab
        self.glowPulse = glowPulse
        self.upcomingBookings = upcomingBookings
        self.pastBookings = pastBookings
    }

    // MARK: Sample data

    static let sampleUpcoming: [UpcomingBooking] = [
        UpcomingBooking(expertName: "Sarah Chen", topic: "Advanced Product Strategy Review",
                        date: "Oct 15, 2024", timeRange: "10:00 AM - 11:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/44.jpg"),
        UpcomingBooking(expertName: "David Miller", topic: "Machine Learning Consultation",
                        date: "Oct 18, 2024", timeRange: "2:30 PM - 3:30 PM",
                        imageURL: "https://randomuser.me/api/portraits/men/32.jpg"),
        UpcomingBooking(expertName: "Emily Davis", topic: "UX Research Plan Feedback",
                        date: "Oct 22, 2024", timeRange: "9:00 AM - 10:00 AM",
                        imageURL: "https://randomuser.me/api/portraits/women/68.jpg"),
    ]

    static let samplePast: [PastBooking] = [
        PastBooking(expertName: "Sarah Johnson", topic: "Advanced Marketing Strategy",
                    date: "Oct 25, 2024", timeRange: "2:00 PM - 3:00 PM", status: .completed),
        PastBooking(expertName: "David Miller", topic: "Product Launch Consultation",
                    date: "Oct 20, 2024", timeRange: "10:00 AM - 11:00 AM", status: .cancelled),
        PastBooking(expertName: "Emily Roberts", topic: "User Experience Audit",
                    date: "Oct 15, 2024", timeRange: "4:00 PM - 5:30 PM", status: .missed),
        PastBooking(expertName: "Michael Brown", topic: "Financial Planning Session",
                    date: "Oct 10, 2024", timeRange: "1:00 PM - 2:00 PM", status: .completed),
    ]
}
