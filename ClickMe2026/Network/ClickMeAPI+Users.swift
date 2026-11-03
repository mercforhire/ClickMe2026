//
//  ClickMeAPI+Users.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    /// `POST /users/:id/report` — thread-independent user report.
    /// Use this from a profile surface where no chat exists yet; for
    /// in-chat reports keep calling `chatAction(id:action:)`. See
    /// `docs/ios/USER-REPORTING.md` §1.
    ///
    /// Expected error codes (handle at call site):
    /// - 403 `ACCOUNT_SUSPENDED` → caller is suspended; let the global
    ///   networking handler route to the suspension screen
    /// - 404 `NOT_FOUND` → target no longer exists; show neutral
    ///   "user unavailable"
    /// - 422 `CANNOT_REPORT_SELF` → hide the Report action on the
    ///   user's own profile; shouldn't happen if the UI gates on
    ///   `isSelfView`
    /// - 429 `TOO_MANY_REQUESTS` → "Please try again later."
    func reportUser(
        id: UUID,
        reason: UserReportReason,
        details: String?
    ) async throws -> SuccessDataResponse<UserReportData> {
        let body = ReportUserRequest(reason: reason, details: details)
        return try await service.httpRequest(
            url: url(.reportUser, id: id),
            method: .post,
            body: body
        )
    }
}
