//
//  FieldError.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// A single field-level validation failure inside `FieldValidationErrorResponse.errors`.
struct FieldError: Decodable {
    let field: String
    let message: String
}
