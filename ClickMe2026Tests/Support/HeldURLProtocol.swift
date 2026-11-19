//
//  HeldURLProtocol.swift
//  ClickMe2026Tests
//
//  A `URLProtocol` that parks selected requests until the test answers them,
//  so a test can land responses in any order. `MockURLProtocol` answers inside
//  `startLoading` on the shared URL loading thread, so it cannot hold two
//  requests at once. This one parks no thread: `startLoading` stores the
//  request and returns, and `release` answers it later from the test.
//
//  Requests the test does not hold are answered straight away by `otherwise`.
//

import Foundation
@testable import ClickMe2026

final class HeldURLProtocol: URLProtocol {

    typealias Reply = (status: Int, body: Data)

    private static let lock = NSLock()
    nonisolated(unsafe) private static var held: [HeldURLProtocol] = []
    nonisolated(unsafe) private static var shouldHold: @Sendable (URLRequest) -> Bool = { _ in false }
    nonisolated(unsafe) private static var otherwise: @Sendable (URLRequest) -> Reply = { _ in (404, Data()) }

    /// Clears every held request and installs the rules. Call once per test, before any request.
    /// - Parameters:
    ///   - hold: True for a request the test will answer itself.
    ///   - otherwise: The immediate answer for every other request.
    static func configure(
        hold: @escaping @Sendable (URLRequest) -> Bool,
        otherwise: @escaping @Sendable (URLRequest) -> Reply
    ) {
        lock.withLock {
            held = []
            shouldHold = hold
            self.otherwise = otherwise
        }
    }

    /// Replaces the hold rule only, keeping the immediate answers. Requests already held stay held.
    static func setHold(_ hold: @escaping @Sendable (URLRequest) -> Bool) {
        lock.withLock { shouldHold = hold }
    }

    /// Builds a `ClickMeAPI` whose traffic runs through this protocol.
    @MainActor
    static func makeAPI() -> ClickMeAPI {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [HeldURLProtocol.self]
        let service = NetworkService(session: URLSession(configuration: config))
        return ClickMeAPI(baseURL: APITestFactory.baseURL, service: service)
    }

    /// How many requests are waiting for an answer.
    static var heldCount: Int {
        lock.withLock { held.count }
    }

    /// Answers the oldest held request for which `matches` is true. Returns false when none matches.
    @discardableResult
    static func release(where matches: (URLRequest) -> Bool, status: Int = 200, body: Data) -> Bool {
        let target: HeldURLProtocol? = lock.withLock {
            guard let index = held.firstIndex(where: { matches($0.request) }) else { return nil }
            return held.remove(at: index)
        }
        guard let target else { return false }
        target.finish(status: status, body: body)
        return true
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let (hold, fallback) = Self.lock.withLock { (Self.shouldHold, Self.otherwise) }
        if hold(request) {
            Self.lock.withLock { Self.held.append(self) }
        } else {
            let reply = fallback(request)
            finish(status: reply.status, body: reply.body)
        }
    }

    override func stopLoading() {}

    private func finish(status: Int, body: Data) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}
