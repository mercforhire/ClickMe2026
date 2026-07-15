//
//  SuccessMessageResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Success envelope for operations that produce a confirmation message rather than
/// structured data: `{ status: "success", message: "..." }`.
struct SuccessMessageResponse: Decodable {
    let status: String
    let message: String
}
