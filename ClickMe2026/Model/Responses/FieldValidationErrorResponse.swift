//
//  FieldValidationErrorResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Field-level validation failure envelope emitted for `ValidationError`.
/// `code` is present only when validation was raised with an explicit code
/// (e.g. `VALIDATION_ERROR` on password reset 422). Omitted on login 422.
struct FieldValidationErrorResponse: Decodable {
    let status: String
    let code: ErrorCode?
    let errors: [FieldError]

    // Lenient `code` decode — matches `StandardErrorResponse`. Unknown
    // server codes decode to nil instead of failing the whole payload.
    private enum CodingKeys: String, CodingKey { case status, code, errors }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(String.self, forKey: .status)
        self.errors = try container.decode([FieldError].self, forKey: .errors)
        let rawCode = try container.decodeIfPresent(String.self, forKey: .code)
        self.code = rawCode.flatMap(ErrorCode.init(rawValue:))
    }
}
