//
//  MockURLProtocol.swift
//  ClickMe2026Tests
//
//  Intercepts URLSession requests so tests can stub HTTP responses without
//  hitting the network. Register on a `URLSessionConfiguration.ephemeral`
//  and pass that session into `NetworkService`.
//

import Foundation

final class MockURLProtocol: URLProtocol {

    /// Set by each test to shape the mocked response.
    /// Return `(HTTPURLResponse, Data)` on success, or throw to simulate a
    /// transport-layer error.
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    /// Records every request that flows through the mock. Reset per-test.
    nonisolated(unsafe) static var recordedRequests: [URLRequest] = []

    static func reset() {
        handler = nil
        recordedRequests = []
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.recordedRequests.append(request)
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
