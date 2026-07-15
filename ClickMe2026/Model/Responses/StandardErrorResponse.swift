//
//  StandardErrorResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Standard error envelope emitted for `AppError` and unknown errors.
/// `code` is omitted when the error was constructed with a null code
/// (e.g. `POST /auth/login` 401, Multer 429).
struct StandardErrorResponse: Decodable {
    let status: String
    let code: ErrorCode?
    let message: String
}
