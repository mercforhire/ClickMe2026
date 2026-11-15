//
//  Error+UserMessage.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

extension Error {

    /// User-facing string for any Error thrown by the network layer.
    ///
    /// Prefers the server-provided `StandardErrorResponse.message` when the
    /// error is a `NetworkError.httpError` carrying a decodable body — that
    /// message is authored for humans and localised server-side. Falls back
    /// to `LocalizedError.errorDescription` (custom Swift errors) and
    /// finally to `localizedDescription` (framework errors like URLError).
    ///
    /// Callers use this in place of the (formerly copy-pasted)
    /// `private static func errorMessage(for:)` helper.
    var userMessage: String {
        if let netError = self as? NetworkError,
           case let .httpError(_, data) = netError,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }

    /// The per-field failures of a `422 VALIDATION_ERROR`, or `[]` for any
    /// other error.
    ///
    /// The backend's `validate` middleware answers a rejected body with a
    /// `FieldValidationErrorResponse` whose `errors[].field` is a dotted path
    /// such as `basic.first_name`. Branches on `ErrorCode`, never on message
    /// text. The body is a best-effort read, so one that does not decode gives
    /// `[]` and the caller falls back to `userMessage`.
    var validationFieldErrors: [FieldError] {
        guard let netError = self as? NetworkError,
              case let .httpError(statusCode, data) = netError,
              statusCode == 422,
              let response = try? JSONDecoder().decode(FieldValidationErrorResponse.self, from: data),
              response.code == .validationError
        else { return [] }
        return response.errors
    }
}

/// One fixed string, so no case can leak the wrapped error (decoder paths,
/// type names) into the UI. `userMessage` still prefers the server's message
/// for an `httpError` that carries one.
extension NetworkError: LocalizedError {
    var errorDescription: String? { "Something went wrong. Please try again." }
}
