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

    init(session: URLSession? = nil) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
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
            let str = try container.decode(String.self)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let d = formatter.date(from: str) { return d }
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let d = formatter.date(from: str) { return d }
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
        parameters: [String: Any]? = nil
    ) async throws -> T {
        let request = try buildRequest(url: url, method: method, parameters: parameters)
        return try await send(request)
    }

    // MARK: - Encodable body
    func httpRequest<T: Decodable, Body: Encodable>(
        url: String,
        method: HTTPMethod,
        body: Body
    ) async throws -> T {
        let request = try buildRequest(url: url, method: method, encodableBody: body)
        return try await send(request)
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
    private func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        do {
            return try jsonDecoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
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
