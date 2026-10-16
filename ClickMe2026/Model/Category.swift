//
//  Category.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

struct Category: Codable, Hashable, Identifiable {
    let id: String
    let name: String
    let iconName: String?
    let colorAccent: String?
    let description: String?
}
