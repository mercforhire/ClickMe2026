//
//  InitiateBookingData.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Expert + topic context for the booking flow initiation step.
struct InitiateBookingData: Decodable {
    struct Expert: Decodable {
        let id: UUID
        let name: String
        let avatarUrl: String?
        let hourlyRate: Double?
        let hourlyRateCurrency: String?
    }

    struct Topic: Decodable {
        let id: UUID
        let title: String
        let description: String?
        let price: Double?
        let currency: String?
        let durationMinutes: Int
        let isFree: Bool
    }

    let expert: Expert
    let topic: Topic
    let availabilityPointer: String
}
