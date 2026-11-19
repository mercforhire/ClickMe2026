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

    typealias Handler = (URLRequest) throws -> (HTTPURLResponse, Data)

    /// Guards `storedHandler` and `requestLog`. A test writes the handler on the main actor while
    /// the URL loading thread reads it, and the URL loading thread appends to the log while a test
    /// may be polling `recordedRequests`.
    private static let requestLock = NSLock()
    nonisolated(unsafe) private static var storedHandler: Handler?
    nonisolated(unsafe) private static var requestLog: [URLRequest] = []

    /// Set by each test to shape the mocked response.
    /// Return `(HTTPURLResponse, Data)` on success, or throw to simulate a
    /// transport-layer error. Reads and writes go through the lock; `startLoading` reads a snapshot
    /// and runs it outside the lock.
    static var handler: Handler? {
        get { requestLock.withLock { storedHandler } }
        set { requestLock.withLock { storedHandler = newValue } }
    }

    /// Records every request that flows through the mock. Reset per-test.
    /// Read-only: a read-modify-write such as `append` would not be atomic. Clear it with
    /// `reset()`, or `clearRecordedRequests()` when the handler must stay.
    static var recordedRequests: [URLRequest] {
        requestLock.withLock { requestLog }
    }

    static func reset() {
        requestLock.withLock {
            storedHandler = nil
            requestLog = []
        }
    }

    /// Empties the request log and keeps the handler, for a test that stops counting the setup requests.
    static func clearRecordedRequests() {
        requestLock.withLock { requestLog = [] }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let recorded = request
        let handler: Handler? = Self.requestLock.withLock {
            Self.requestLog.append(recorded)
            return Self.storedHandler
        }
        guard let handler else {
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
