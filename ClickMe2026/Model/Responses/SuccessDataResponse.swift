//
//  SuccessDataResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Standard success envelope wrapping an endpoint-specific data payload:
/// `{ status: "success", data: { ... } }`.
struct SuccessDataResponse<Data: Decodable>: Decodable {
    let status: String
    let data: Data
}
