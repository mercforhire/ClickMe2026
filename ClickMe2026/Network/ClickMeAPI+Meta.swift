//
//  ClickMeAPI+Meta.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getExpertiseTags() async throws -> SuccessDataResponse<ExpertiseTagsPayload> {
        try await service.httpRequest(url: url(.getExpertiseTags), method: .get)
    }

    func getCurrencies() async throws -> SuccessDataResponse<CurrenciesPayload> {
        try await service.httpRequest(url: url(.getCurrencies), method: .get)
    }

    func getLanguages() async throws -> SuccessDataResponse<LanguagesPayload> {
        try await service.httpRequest(url: url(.getLanguages), method: .get)
    }
}
