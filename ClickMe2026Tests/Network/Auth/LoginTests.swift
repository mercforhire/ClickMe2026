//
//  LoginTests.swift
//  ClickMe2026Tests
//
//  Reference example for how to test `ClickMeAPI+Auth` endpoints without
//  hitting the network. Follow this pattern for the remaining endpoints
//  (`forgotPassword`, `resetPassword`, `/me`, etc.).
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ClickMeAPI+Auth · login", .serialized)
@MainActor
struct LoginTests {

    // MARK: - Request shape

    @Test("sends POST to /auth/login with JSON body containing email and password")
    func sendsCorrectRequest() async throws {
        let email = "ada@example.com"
        let password = "hunter2!"

        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = Bundle.tests.jsonData(named: "login_success", subdirectory: "Auth")
            return (response, data)
        }

        _ = try await api.login(email: email, password: password)

        // Exactly one request went out, hitting the expected URL + method.
        #expect(MockURLProtocol.recordedRequests.count == 1)
        let sent = try #require(MockURLProtocol.recordedRequests.first)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "\(APITestFactory.baseURL)/auth/login")

        // Body serialized to the shape the server expects.
        let bodyData = try #require(sent.httpBodyOrStreamData())
        let json = try #require(
            JSONSerialization.jsonObject(with: bodyData) as? [String: String]
        )
        #expect(json["email"] == email)
        #expect(json["password"] == password)
    }

    // MARK: - Success

    @Test("decodes successful response into SuccessDataResponse<LoginData>")
    func decodesSuccessResponse() async throws {
        let api = APITestFactory.make(status: 200, fixture: "login_success")

        let response = try await api.login(email: "ada@example.com", password: "hunter2!")

        #expect(response.status == "success")
        #expect(response.data.token.hasPrefix("eyJhbGciOi"))
        #expect(response.data.user.firstName == "Ada")
        #expect(response.data.user.lastName == "Lovelace")
        #expect(response.data.user.role == .expert)
    }

    // MARK: - Error mapping

    @Test("maps 401 to NetworkError.httpError with decodable StandardErrorResponse")
    func maps401ToHTTPError() async throws {
        let api = APITestFactory.make(status: 401, fixture: "login_401")

        await #expect(throws: NetworkError.self) {
            _ = try await api.login(email: "ada@example.com", password: "wrong-pw")
        }

        // Verify the caller can decode the server error body.
        do {
            _ = try await api.login(email: "ada@example.com", password: "wrong-pw")
            Issue.record("Expected login to throw for 401")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect(statusCode == 401)
            let decoded = try JSONDecoder().decode(StandardErrorResponse.self, from: data)
            #expect(decoded.status == "error")
            #expect(decoded.message == "The email or password is incorrect.")
        } catch {
            Issue.record("Expected httpError but got \(error)")
        }
    }

    @Test("maps 422 field-validation errors to httpError so callers can decode field errors")
    func maps422ToHTTPError() async throws {
        let api = APITestFactory.make(status: 422, fixture: "login_422")

        do {
            _ = try await api.login(email: "ada@example.com", password: "short")
            Issue.record("Expected login to throw for 422")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect(statusCode == 422)
            let decoded = try JSONDecoder().decode(FieldValidationErrorResponse.self, from: data)
            #expect(decoded.errors.first?.field == "password")
        } catch {
            Issue.record("Expected httpError but got \(error)")
        }
    }

    @Test("propagates decoding failure when body doesn't match the expected shape")
    func decodingFailure() async throws {
        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            // Well-formed JSON but wrong shape — no `data` key.
            return (response, Data(#"{"status":"success"}"#.utf8))
        }

        do {
            _ = try await api.login(email: "ada@example.com", password: "hunter2!")
            Issue.record("Expected login to throw for malformed body")
        } catch let NetworkError.decodingFailed(underlying) {
            #expect(underlying is DecodingError)
        } catch {
            Issue.record("Expected decodingFailed but got \(error)")
        }
    }

    // MARK: - Parameterized status-code coverage

    @Test(
        "any 4xx/5xx status is surfaced as httpError with the raw body",
        arguments: [400, 403, 404, 429, 500, 503]
    )
    func propagatesArbitraryErrorStatus(_ code: Int) async throws {
        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: code,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!
            return (response, Data(#"{"status":"error"}"#.utf8))
        }

        do {
            _ = try await api.login(email: "ada@example.com", password: "hunter2!")
            Issue.record("Expected login to throw for HTTP \(code)")
        } catch let NetworkError.httpError(statusCode, _) {
            #expect(statusCode == code)
        } catch {
            Issue.record("Expected httpError but got \(error)")
        }
    }
}

// MARK: - URLRequest body helper

private extension URLRequest {
    /// Returns the request body whether it was set as `httpBody` (which
    /// URLSession may drop into `httpBodyStream` when the request is dispatched).
    func httpBodyOrStreamData() -> Data? {
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
}
