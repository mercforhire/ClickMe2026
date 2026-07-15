//
//  UpcomingBookingViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class UpcomingBookingViewModel: ObservableObject {

    // MARK: Content
    @Published var bookingID: String
    @Published var expertName: String
    @Published var expertTitle: String
    @Published var expertImageURL: String
    @Published var expertRating: Double
    @Published var reviewCount: Int
    @Published var topic: String
    @Published var consultationFee: String
    @Published var date: String
    @Published var timeRange: String
    @Published var joinLink: String
    @Published var preparationNote: String
    @Published var attachmentName: String?

    init(
        bookingID: String = "#CM-98231",
        expertName: String = "Sarah Chen",
        expertTitle: String = "Senior UX Architect",
        expertImageURL: String = UpcomingBookingViewModel.sampleImageURL,
        expertRating: Double = 4.9,
        reviewCount: Int = 128,
        topic: String = "Advanced Product Strategy Review",
        consultationFee: String = "$150 / session",
        date: String = "Oct 15, 2024",
        timeRange: String = "10:00 AM - 11:00 AM",
        joinLink: String = "skype.com/j/clickme-sarah",
        preparationNote: String = "Please have your current product roadmap and user persona documents ready. We'll be diving deep into the Q4 objectives and identifying key friction points in the user journey.",
        attachmentName: String? = "Current_Strategy_V2.pdf"
    ) {
        self.bookingID = bookingID
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.expertRating = expertRating
        self.reviewCount = reviewCount
        self.topic = topic
        self.consultationFee = consultationFee
        self.date = date
        self.timeRange = timeRange
        self.joinLink = joinLink
        self.preparationNote = preparationNote
        self.attachmentName = attachmentName
    }

    // MARK: Defaults

    static let sampleImageURL = "https://lh3.googleusercontent.com/aida-public/AB6AXuD-ENFxFRN4Pff6e-HrtvXOkZVAENbGDLU3aUuz12EcHXP9HvoTM_zvDWdf4LxyQddQN21Q8YpuIhWRqQGfZh0dpmdR2Ak2nVLOJHYjJ4VnnqUvKZFfnVEqpCh3EEVR4_rFIPxEq0aLuXAl3WZJV77ezuINaUGUNuF8-InR2eBriYCBRpRRcjNis7k0CYuPQqz5rZxoz0bH2GKqD_P6sPF4dRp61iOAwQM6dQLAKVg_5vEwhuvj6qfMbzkar2rx3hF-NkU5NPuUI2g"
}
