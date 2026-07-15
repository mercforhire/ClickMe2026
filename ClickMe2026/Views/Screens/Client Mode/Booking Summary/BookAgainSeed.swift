//
//  BookAgainSeed.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-10.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Payload handed from `BookingSummaryView` up to its NavigationStack owner
/// when the user taps **Book Again**. Carries exactly the fields
/// `MakeABookingView(expertId:expertName:expertTitle:expertImageURL:)`
/// needs, so the caller can push that screen without re-fetching the
/// booking detail.
struct BookAgainSeed: Hashable {
    let expertId: UUID
    let expertName: String
    let expertTitle: String
    let expertImageURL: String
}
