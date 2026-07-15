//
//  ClickMeAPI+Auth.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func login(email: String, password: String) async throws -> SuccessDataResponse<LoginData> {
        try await service.httpRequest(
            url: url(.login),
            method: .post,
            parameters: ["email": email, "password": password]
        )
    }

    func forgotPassword(identity: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.forgotPassword),
            method: .post,
            parameters: ["identity": identity]
        )
    }

    func resetPassword(
        email: String,
        code: String,
        password: String,
        passwordConfirmation: String
    ) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.resetPassword),
            method: .post,
            parameters: [
                "email": email,
                "code": code,
                "password": password,
                "password_confirmation": passwordConfirmation
            ]
        )
    }
}
