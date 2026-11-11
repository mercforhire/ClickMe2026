//
//  URLRequest+Body.swift
//  ClickMe2026Tests
//
//  Shared request-body reader for tests that assert on what was sent.
//  Named differently from the private helper in LoginTests.swift on purpose.
//

import Foundation

extension URLRequest {

    /// The request body whether it was set as `httpBody` or, once URLSession
    /// dispatched the request, moved into `httpBodyStream`.
    func bodyDataForTest() -> Data? {
        if let body = httpBody { return body }
        guard let stream = httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            if read <= 0 { break }
            data.append(buffer, count: read)
        }
        return data
    }

    /// The JSON body decoded as a dictionary, or `nil` when there is no object body.
    func jsonBodyForTest() -> [String: Any]? {
        guard let data = bodyDataForTest() else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}
