//
//  NetworkService.swift
//  ClickMe
//
//  Created by Leon Chen on 2024-01-02.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data)
    case decodingFailed(Error)
    case encodingFailed(Error)
    case invalidDate
}

/// A single part of a multipart/form-data request body. Use `filename` + `mimeType`
/// for file parts; leave them nil for plain text/value fields.
struct MultipartPart {
    let name: String
    let filename: String?
    let mimeType: String?
    let data: Data

    static func text(name: String, value: String) -> MultipartPart {
        MultipartPart(name: name, filename: nil, mimeType: nil, data: Data(value.utf8))
    }

    static func file(name: String, filename: String, mimeType: String, data: Data) -> MultipartPart {
        MultipartPart(name: name, filename: filename, mimeType: mimeType, data: data)
    }
}

final class NetworkService {

    private let session: URLSession
    private let jsonDecoder: JSONDecoder
    private let jsonEncoder: JSONEncoder
    private let dateFormatter: DateFormatter

    /// Bearer token used for authenticated requests.
    var bearerToken: String?

    /// Coordinator for the `/auth/refresh` cycle. Assigned by
    /// `UserManager` on construction. When non-nil, a 401 on any
    /// authed request triggers refresh-then-retry-once instead of
    /// bubbling straight to the caller. Nil disables the interceptor
    /// (used by tests / previews that don't wire an auth manager).
    var authTokenRefresher: TokenRefresher?

    /// Called from the main actor when a `403 ACCOUNT_SUSPENDED` is
    /// seen on ANY request. `UserManager` wires this to clear tokens +
    /// disconnect the realtime socket + raise a suspended-flag that the
    /// shell's splash/login route can observe. The original error still
    /// propagates to the caller so individual VMs can also surface it.
    /// See `docs/ios/USER-REPORTING.md` §4.
    var suspensionHandler: (@MainActor @Sendable () -> Void)?

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        self.session = session ?? URLSession(configuration: config)

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        self.dateFormatter = formatter

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)

            // Postgres/JS backends often serialize timestamps with
            // microsecond precision (e.g. `.983286`). `DateFormatter`'s
            // `.SSS` pattern only accepts millisecond precision (3 digits),
            // so truncate any longer fractional-second run to 3 digits
            // before parsing.
            let normalized = raw.replacingOccurrences(
                of: #"\.(\d{3})\d+"#,
                with: ".$1",
                options: .regularExpression
            )

            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let d = formatter.date(from: normalized) { return d }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let d = formatter.date(from: normalized) { return d }
            throw NetworkError.invalidDate
        }
        self.jsonDecoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        self.jsonEncoder = encoder
    }

    // MARK: - Dictionary body / query
    func httpRequest<T: Decodable>(
        url: String,
        method: HTTPMethod,
        parameters: [String: Any]? = nil,
        headers: [String: String]? = nil
    ) async throws -> T {
        var request = try buildRequest(url: url, method: method, parameters: parameters)
        apply(headers: headers, to: &request)
        return try await send(request)
    }

    // MARK: - Encodable body
    func httpRequest<T: Decodable, Body: Encodable>(
        url: String,
        method: HTTPMethod,
        body: Body,
        headers: [String: String]? = nil
    ) async throws -> T {
        var request = try buildRequest(url: url, method: method, encodableBody: body)
        apply(headers: headers, to: &request)
        return try await send(request)
    }

    /// Applies caller-supplied headers on top of the built request. Used
    /// for one-off headers like `Idempotency-Key` on the withdraw endpoint;
    /// standard `Content-Type` / bearer auth are already set by the
    /// underlying builders and won't be clobbered by nil headers.
    private func apply(headers: [String: String]?, to request: inout URLRequest) {
        guard let headers else { return }
        for (name, value) in headers {
            request.setValue(value, forHTTPHeaderField: name)
        }
    }

    // MARK: - Multipart upload
    func multipartUpload<T: Decodable>(
        url: String,
        method: HTTPMethod = .post,
        parts: [MultipartPart]
    ) async throws -> T {
        let request = try buildMultipartRequest(url: url, method: method, parts: parts)
        return try await send(request)
    }

    // MARK: - Send + decode

    /// Public entry point. Runs `sendRaw`, and on a 401 from an
    /// authed endpoint triggers a single `authTokenRefresher.refresh()`
    /// before retrying the same request once with the freshened
    /// bearer. The refresh endpoint itself is exempt (it's on the
    /// public-paths list), so no recursion is possible.
    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            return try await sendRaw(request)
        } catch let error {
            // Global 403 ACCOUNT_SUSPENDED trap. Fires BEFORE the
            // generic 401-refresh path so a suspended user never
            // triggers a refresh loop. We still rethrow so the caller
            // can show its own message if it wants, but the handler
            // has already cleared auth + disconnected the socket.
            if case let NetworkError.httpError(403, data) = error,
               isAccountSuspendedError(data: data),
               let handler = suspensionHandler
            {
                await handler()
                throw error
            }

            guard case NetworkError.httpError(401, _) = error,
                  shouldAttemptRefresh(for: request),
                  let refresher = authTokenRefresher
            else { throw error }

            let refreshed = await refresher.refresh()
            guard refreshed else { throw error }

            // Re-apply auth so the retry picks up the rotated token.
            // `applyAuth` reads the current `bearerToken` — which the
            // refresher's completion callback (in `UserManager`) has
            // already swapped in — and injects it fresh onto a copy of
            // the original request.
            var retry = request
            retry.setValue(nil, forHTTPHeaderField: "Authorization")
            applyAuth(&retry)
            return try await sendRaw(retry)
        }
    }

    /// Peeks the body of a 403 to see whether it's a suspension (vs an
    /// ordinary FORBIDDEN). Uses an isolated decoder to avoid snake-case
    /// drift confusing the shared one.
    private func isAccountSuspendedError(data: Data) -> Bool {
        struct Envelope: Decodable { let code: String? }
        let decoder = JSONDecoder()
        guard let envelope = try? decoder.decode(Envelope.self, from: data) else {
            return false
        }
        return envelope.code == ErrorCode.accountSuspended.rawValue
    }

    /// Fires the URL request, checks status, decodes. No refresh
    /// awareness — the interceptor lives one level up in `send`.
    private func sendRaw<T: Decodable>(_ request: URLRequest) async throws -> T {
        logRequest(request)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        logResponse(request: request, response: httpResponse, data: data)
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    /// Whether a 401 on this request warrants a refresh attempt.
    /// Public endpoints (login / signup / `/auth/refresh` / password
    /// reset) never get bearer headers in the first place — a 401
    /// from those is a genuine credential failure, not an expired
    /// token, so retrying would just loop.
    private func shouldAttemptRefresh(for request: URLRequest) -> Bool {
        guard let urlString = request.url?.absoluteString else { return false }
        return APIRequestURLs.needAuthToken(url: urlString)
    }

    // MARK: - Debug logging
    //
    // Compiled out of Release builds. Prints the outgoing request line +
    // body and the raw response status + body to Xcode's console, so
    // server-side validation errors can be inspected directly.

    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "?"
        let url = request.url?.absoluteString ?? "?"
        print("→ \(method) \(url)")
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            let redacted = headers.map { key, value in
                key.lowercased() == "authorization" ? "\(key): Bearer …" : "\(key): \(value)"
            }.joined(separator: ", ")
            print("  headers: \(redacted)")
        }
        if let body = request.httpBody,
           let string = String(data: body, encoding: .utf8),
           !string.isEmpty
        {
            print("  body: \(string)")
        }
        #endif
    }

    private func logResponse(request: URLRequest, response: HTTPURLResponse, data: Data) {
        #if DEBUG
        let url = request.url?.absoluteString ?? "?"
        print("← \(response.statusCode) \(url)")
        if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
            let trimmed = string.count > 2000 ? "\(string.prefix(2000))… (truncated)" : string
            print("  body: \(trimmed)")
        }
        #endif
    }

    // MARK: - Request builders

    private func buildRequest(
        url: String,
        method: HTTPMethod,
        parameters: [String: Any]?
    ) throws -> URLRequest {
        let sendsBody = (method != .get && method != .delete)
        guard let finalURL = makeURL(from: url, query: sendsBody ? nil : parameters) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue

        if sendsBody, let parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }

        applyAuth(&request)
        return request
    }

    private func buildRequest<Body: Encodable>(
        url: String,
        method: HTTPMethod,
        encodableBody: Body
    ) throws -> URLRequest {
        guard let finalURL = makeURL(from: url, query: nil) else {
            throw NetworkError.invalidURL
        }
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try jsonEncoder.encode(encodableBody)
        } catch {
            throw NetworkError.encodingFailed(error)
        }
        applyAuth(&request)
        return request
    }

    private func buildMultipartRequest(
        url: String,
        method: HTTPMethod,
        parts: [MultipartPart]
    ) throws -> URLRequest {
        guard let finalURL = makeURL(from: url, query: nil) else {
            throw NetworkError.invalidURL
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: finalURL)
        request.httpMethod = method.rawValue
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        for part in parts {
            body.appendString("--\(boundary)\r\n")
            if let filename = part.filename, let mime = part.mimeType {
                body.appendString("Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\"\r\n")
                body.appendString("Content-Type: \(mime)\r\n\r\n")
            } else {
                body.appendString("Content-Disposition: form-data; name=\"\(part.name)\"\r\n\r\n")
            }
            body.append(part.data)
            body.appendString("\r\n")
        }
        body.appendString("--\(boundary)--\r\n")
        request.httpBody = body

        applyAuth(&request)
        return request
    }

    private func applyAuth(_ request: inout URLRequest) {
        guard let token = bearerToken,
              let urlString = request.url?.absoluteString,
              APIRequestURLs.needAuthToken(url: urlString) else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    private func makeURL(from url: String, query: [String: Any]?) -> URL? {
        guard var components = URLComponents(string: url) else { return nil }
        if let query, !query.isEmpty {
            let items = query.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            components.queryItems = (components.queryItems ?? []) + items
        }
        return components.url
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}

// MARK: - Token refresher (single-flight)

/// Serialises the `/auth/refresh` cycle so concurrent 401s coalesce
/// into a single in-flight refresh call. Multiple callers awaiting
/// `refresh()` share the same `Task`; the actor's serial execution
/// guarantees only one refresh attempt is dispatched per token
/// generation.
///
/// This matters because the backend enables refresh-token reuse
/// detection — replaying an old refresh token (as would happen if N
/// concurrent 401s each fired their own POST) is treated as a stolen
/// credential and the whole session is revoked. Single-flighting is
/// therefore not a nice-to-have; it's a correctness requirement.
actor TokenRefresher {

    /// The in-flight refresh task, if any. Retained until the
    /// underlying work completes so late arrivals can await the same
    /// result rather than firing a duplicate call.
    private var inFlight: Task<Bool, Never>?

    /// Closure that performs the actual refresh (typically
    /// `UserManager.performRefreshCycle`). Returns `true` when the
    /// caller should retry the original request, `false` otherwise
    /// (dead session, network error, etc.).
    private let perform: @Sendable () async -> Bool

    init(perform: @escaping @Sendable () async -> Bool) {
        self.perform = perform
    }

    func refresh() async -> Bool {
        if let task = inFlight {
            return await task.value
        }
        let task = Task<Bool, Never> { [perform] in await perform() }
        inFlight = task
        let result = await task.value
        // Clear so a *future* 401 (e.g. after the freshly-refreshed
        // token also expires later in the day) starts its own cycle
        // rather than replaying this task's cached result.
        inFlight = nil
        return result
    }
}
