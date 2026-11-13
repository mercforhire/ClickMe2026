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

    /// Guards `requestLog`. The URL loading thread appends while a test may be polling `recordedRequests`.
    private static let requestLock = NSLock()
    nonisolated(unsafe) private static var requestLog: [URLRequest] = []

    /// Records every request that flows through the mock. Reset per-test.
    /// Reads and writes go through one lock, so a test can poll it while the URL loading thread appends.
    static var recordedRequests: [URLRequest] {
        get { requestLock.withLock { requestLog } }
        set { requestLock.withLock { requestLog = newValue } }
    }

    static func reset() {
        handler = nil
        requestLock.withLock { requestLog = [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let recorded = request
        Self.requestLock.withLock { Self.requestLog.append(recorded) }
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
