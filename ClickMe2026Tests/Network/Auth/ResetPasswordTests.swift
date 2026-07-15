//
//  ResetPasswordTests.swift
//  ClickMe2026Tests
//
//  Covers `ClickMeAPI+Auth.resetPassword` — request shape, success decoding,
//  and error mapping for the two documented failure modes:
//    • 400 EXPIRED_TOKEN (bad / expired / used / max-attempts / unknown email)
//    • 422 VALIDATION_ERROR (password mismatch or weak password)
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ClickMeAPI+Auth · resetPassword", .serialized)
@MainActor
struct ResetPasswordTests {

    // MARK: - Request shape

    @Test("sends POST to /auth/password/reset with email, code, password, password_confirmation")
    func sendsCorrectRequest() async throws {
        let email = "ada@example.com"
        let code = "123456"
        let password = "N3wSecur3P@ss!"
        let confirmation = "N3wSecur3P@ss!"

        let api = APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let data = Bundle.tests.jsonData(named: "reset_password_success", subdirectory: "Auth")
            return (response, data)
        }

        _ = try await api.resetPassword(
            email: email,
            code: code,
            password: password,
            passwordConfirmation: confirmation
        )

        #expect(MockURLProtocol.recordedRequests.count == 1)
        let sent = try #require(MockURLProtocol.recordedRequests.first)
        #expect(sent.httpMethod == "POST")
        #expect(sent.url?.absoluteString == "\(APITestFactory.baseURL)/auth/password/reset")

        let bodyData = try #require(sent.httpBodyOrStreamData())
        let json = try #require(
            JSONSerialization.jsonObject(with: bodyData) as? [String: String]
        )
        #expect(json["email"] == email)
        #expect(json["code"] == code)
        #expect(json["password"] == password)
        #expect(json["password_confirmation"] == confirmation)
    }

    // MARK: - Success

    @Test("decodes 200 into SuccessMessageResponse")
    func decodesSuccessResponse() async throws {
        let api = APITestFactory.make(status: 200, fixture: "reset_password_success")

        let response = try await api.resetPassword(
            email: "ada@example.com",
            code: "123456",
            password: "N3wSecur3P@ss!",
            passwordConfirmation: "N3wSecur3P@ss!"
        )

        #expect(response.status == "success")
        #expect(!response.message.isEmpty)
    }

    // MARK: - Error mapping

    @Test("maps 400 EXPIRED_TOKEN to httpError with a decodable StandardErrorResponse")
    func maps400ToHTTPError() async throws {
        let api = APITestFactory.make(status: 400, fixture: "reset_password_400")

        do {
            _ = try await api.resetPassword(
                email: "ada@example.com",
                code: "000000",
                password: "N3wSecur3P@ss!",
                passwordConfirmation: "N3wSecur3P@ss!"
            )
            Issue.record("Expected resetPassword to throw for 400 EXPIRED_TOKEN")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect(statusCode == 400)
            let decoded = try JSONDecoder().decode(StandardErrorResponse.self, from: data)
            #expect(decoded.status == "error")
            #expect(decoded.code == .expiredToken)
        } catch {
            Issue.record("Expected httpError but got \(error)")
        }
    }

    @Test("maps 422 VALIDATION_ERROR to httpError with decodable per-field errors")
    func maps422ToHTTPError() async throws {
        let api = APITestFactory.make(status: 422, fixture: "reset_password_422")

        do {
            _ = try await api.resetPassword(
                email: "ada@example.com",
                code: "123456",
                password: "short",
                passwordConfirmation: "mismatch"
            )
            Issue.record("Expected resetPassword to throw for 422")
        } catch let NetworkError.httpError(statusCode, data) {
            #expect(statusCode == 422)
            let decoded = try JSONDecoder().decode(FieldValidationErrorResponse.self, from: data)
            let fields = decoded.errors.map(\.field)
            #expect(fields.contains("password"))
            #expect(fields.contains("password_confirmation"))
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
