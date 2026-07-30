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

    // Custom decode so an unknown `code` value (e.g. a newly-added
    // server-side case not yet in our `ErrorCode` enum) decodes to
    // `nil` rather than failing the whole payload. Without this,
    // callers doing `try? JSONDecoder().decode(StandardErrorResponse.self, from:)`
    // silently drop the error body and fall back to a generic alert.
    private enum CodingKeys: String, CodingKey { case status, code, message }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(String.self, forKey: .status)
        self.message = try container.decode(String.self, forKey: .message)
        let rawCode = try container.decodeIfPresent(String.self, forKey: .code)
        self.code = rawCode.flatMap(ErrorCode.init(rawValue:))
    }
}
