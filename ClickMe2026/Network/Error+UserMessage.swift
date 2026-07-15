//
//  Error+UserMessage.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
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
        if case let NetworkError.httpError(_, data) = self,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (self as? LocalizedError)?.errorDescription ?? localizedDescription
    }
}
