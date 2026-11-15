//
//  ProfileSaveErrorMapperTests.swift
//  ClickMe2026Tests
//
//  G-05-6 (SET-01 reopened): a 422 on a Profile Settings save names the fields
//  to check in iOS-owned copy, from a fixed label table in screen order. It never
//  shows the server's field paths or raw validation text. Every other failure
//  keeps `Error.userMessage`.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Profile save error mapper")
struct ProfileSaveErrorMapperTests {

    private static let genericMessage = "Please check the information you entered and try again."
    private static let rawText = "Too small: expected string to have >=1 characters"

    /// A `FieldValidationErrorResponse` body, the way the backend's `validate`
    /// middleware writes it. `code` is omitted when nil.
    private func validation(
        fields: [String], status: Int = 422, code: String? = "VALIDATION_ERROR"
    ) -> NetworkError {
        let errors = fields
            .map { #"{"field":"\#($0)","message":"\#(Self.rawText)"}"# }
            .joined(separator: ",")
        let codePart = code.map { #","code":"\#($0)""# } ?? ""
        let body = #"{"status":"error","message":"\#(Self.genericMessage)","errors":[\#(errors)]\#(codePart)}"#
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    private func standard(status: Int, message: String) -> NetworkError {
        let body = #"{"status":"error","message":"\#(message)"}"#
        return .httpError(statusCode: status, data: Data(body.utf8))
    }

    // MARK: - Naming the fields

    @Test("the production 422 names First Name and Last Name and shows no raw text")
    func productionBody() {
        let error = validation(fields: ["basic.first_name", "basic.last_name"])
        let text = ProfileSaveErrorMapper.message(for: error)

        #expect(text == "Check First Name and Last Name, then try again.")
        #expect(!text.contains("Too small"))
        #expect(!text.contains("basic."))
    }

    @Test("one field reads as is")
    func singleField() {
        let error = validation(fields: ["basic.last_name"])
        #expect(ProfileSaveErrorMapper.message(for: error) == "Check Last Name, then try again.")
    }

    @Test("fields come back in screen order, not server order")
    func screenOrder() {
        let error = validation(fields: ["location.city", "basic.bio", "basic.first_name"])
        #expect(ProfileSaveErrorMapper.message(for: error) == "Check First Name, Bio and City, then try again.")
    }

    @Test("array item paths collapse to one label")
    func dedupesLanguageItems() {
        let error = validation(fields: ["languages.language_ids.0", "languages.custom_languages"])
        #expect(ProfileSaveErrorMapper.message(for: error) == "Check Spoken Languages, then try again.")
    }

    @Test("every table field has its on-screen label")
    func fullTable() {
        let error = validation(fields: [
            "location.country_code", "location.state_province", "location.city", "professional.company",
            "professional.job_title", "basic.bio", "basic.last_name", "basic.first_name", "languages.language_ids"
        ])
        #expect(
            ProfileSaveErrorMapper.message(for: error)
                == "Check First Name, Last Name, Bio, Job Title, Company, City, State/Province, Country "
                + "and Spoken Languages, then try again."
        )
    }

    @Test("a path that only shares a prefix with a key does not match")
    func prefixNeedsDotBoundary() {
        let error = validation(fields: ["basic.first_name_extra"])
        #expect(ProfileSaveErrorMapper.message(for: error) == error.userMessage)
    }

    // MARK: - Fallbacks

    @Test("a 422 whose only field is unmapped keeps the server message")
    func unmappedFieldFallsBack() {
        let error = validation(fields: ["location.timezone_id"])
        #expect(ProfileSaveErrorMapper.message(for: error) == Self.genericMessage)
        #expect(ProfileSaveErrorMapper.message(for: error) == error.userMessage)
    }

    @Test("a 422 with no code keeps the server message")
    func noCodeFallsBack() {
        let error = validation(fields: ["basic.first_name"], code: nil)
        #expect(ProfileSaveErrorMapper.message(for: error) == error.userMessage)
    }

    @Test("a 409 keeps the server message")
    func conflictFallsBack() {
        let error = standard(status: 409, message: "Already exists.")
        #expect(ProfileSaveErrorMapper.message(for: error) == "Already exists.")
    }

    @Test("a 500 keeps the server message")
    func serverErrorFallsBack() {
        let error = standard(status: 500, message: "Something broke.")
        #expect(ProfileSaveErrorMapper.message(for: error) == "Something broke.")
    }

    @Test("a URLError keeps its own description")
    func transportErrorFallsBack() {
        let error = URLError(.notConnectedToInternet)
        #expect(ProfileSaveErrorMapper.message(for: error) == error.userMessage)
    }

    // MARK: - Error.validationFieldErrors

    @Test("validationFieldErrors returns the errors of a 422 VALIDATION_ERROR")
    func fieldErrorsForValidation() {
        let errors = validation(fields: ["basic.first_name", "basic.last_name"]).validationFieldErrors
        #expect(errors.map(\.field) == ["basic.first_name", "basic.last_name"])
        #expect(errors.allSatisfy { $0.message == Self.rawText })
    }

    @Test("validationFieldErrors is empty for a 409, a non-NetworkError, a body that does not decode and a 422 without a code")
    func fieldErrorsEmptyElsewhere() {
        #expect(standard(status: 409, message: "x").validationFieldErrors.isEmpty)
        #expect(validation(fields: ["basic.first_name"], status: 409).validationFieldErrors.isEmpty)
        #expect(URLError(.timedOut).validationFieldErrors.isEmpty)
        #expect(NetworkError.httpError(statusCode: 422, data: Data("not json".utf8)).validationFieldErrors.isEmpty)
        #expect(validation(fields: ["basic.first_name"], code: nil).validationFieldErrors.isEmpty)
    }
}
