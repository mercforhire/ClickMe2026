//
//  CurrencyItem.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single currency entry from the seeded `currencies` table.
struct CurrencyItem: Decodable {
    let code: String
    let symbol: String
    let name: String
    let minorUnitDigits: Int
}
