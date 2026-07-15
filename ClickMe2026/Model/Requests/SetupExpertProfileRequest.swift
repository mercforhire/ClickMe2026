//
//  SetupExpertProfileRequest.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Body for `PATCH /expert/profile/setup` — initial expert profile setup.
struct SetupExpertProfileRequest: Encodable {
    struct Location: Encodable {
        let city: String
        let provinceState: String
        let countryCode: String
    }

    struct HourlyRate: Encodable {
        let amount: Int
        let currency: String
    }

    let firstName: String
    let location: Location
    let timezone: String
    let languages: [String]
    let expertiseTags: [String]
    let hourlyRate: HourlyRate
}
