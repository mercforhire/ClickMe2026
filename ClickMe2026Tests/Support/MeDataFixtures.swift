//
//  MeDataFixtures.swift
//  ClickMe2026Tests
//
//  Shared `MeData` builder for the topic suites that need an account with a
//  chosen default currency, so a test injects `/me` into `TopicEditorViewModel`
//  instead of reading whatever the shared user manager holds (06-REVIEW IN-07).
//

import Foundation
@testable import ClickMe2026

/// Main-actor isolated because `MeData`'s `Decodable` conformance is: the app
/// target defaults to main-actor isolation and the test target does not.
@MainActor
enum MeDataFixtures {

    /// A decoded `/me` with `pricing_limits`.
    /// - Parameters:
    ///   - defaultCurrency: `pricing_limits.min_session_amount.default_currency`.
    ///   - allowedCurrencies: `pricing_limits.allowed_currencies`. Nil omits the
    ///     key, as an older server does.
    static func me(defaultCurrency: String, allowedCurrencies: [String]?) throws -> MeData {
        let allowed = allowedCurrencies.map { codes in
            "\"allowed_currencies\": [\(codes.map { "\"\($0)\"" }.joined(separator: ","))],"
        } ?? ""
        let json = """
        {
          "id": "55555555-5555-5555-5555-555555555555",
          "email": "expert@example.com",
          "roles": ["client", "expert"],
          "pricing_limits": {
            \(allowed)
            "min_session_amount": {
              "by_currency": { "USD": 500, "CAD": 500 },
              "default_minor_units": 500,
              "default_currency": "\(defaultCurrency)"
            }
          }
        }
        """
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(MeData.self, from: Data(json.utf8))
    }
}
