//
//  APITestFactory.swift
//  ClickMe2026Tests
//
//  Convenience factory that builds a `ClickMeAPI` wired to a `MockURLProtocol`
//  session, so tests can specify the response with a single closure.
//

import Foundation
@testable import ClickMe2026

enum APITestFactory {

    /// The fixed base URL used across tests. Path assertions can compare
    /// against `<baseURL>/<endpoint>` directly.
    static let baseURL = "https://test.clickme.local/api/v1"

    /// Builds a `ClickMeAPI` that routes all traffic through `MockURLProtocol`.
    /// - Parameter respond: Closure invoked for every request; return the
    ///   `(HTTPURLResponse, Data)` you want the client to receive.
    static func make(
        bearerToken: String? = nil,
        respond: @escaping (URLRequest) throws -> (HTTPURLResponse, Data)
    ) -> ClickMeAPI {
        MockURLProtocol.reset()
        MockURLProtocol.handler = respond

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)

        let service = NetworkService(session: session)
        service.bearerToken = bearerToken

        return ClickMeAPI(baseURL: baseURL, service: service)
    }

    /// Convenience: respond with a canned HTTP status + body from a fixture file.
    static func make(
        status: Int,
        fixture name: String,
        subdirectory: String = "Auth"
    ) -> ClickMeAPI {
        let data = Bundle.tests.jsonData(named: name, subdirectory: subdirectory)
        return make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
    }
}
