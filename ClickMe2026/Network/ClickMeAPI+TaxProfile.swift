//
//  ClickMeAPI+TaxProfile.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

// MARK: - Expert tax profile (CRA / Stripe Connect KYC)
//
// Backs the "Tax & Payout Info" screen in expert settings. The TIN is
// treated as sensitive: sent once on save, never returned on read.
// The server may accept the rest of the profile without a TIN as a
// deferred save (returns `saved: false, tin_required: true`).

extension ClickMeAPI {

    /// `GET /expert/tax-profile` — masked read of the caller's tax
    /// profile. `tinOnFile` is a boolean; the TIN itself is never sent
    /// back over the wire, even to the owner.
    func getTaxProfile() async throws -> SuccessDataResponse<TaxProfileData> {
        try await service.httpRequest(url: url(.getTaxProfile), method: .get)
    }

    /// `POST /expert/tax-profile` — save or partial-save. TIN + financial
    /// account identifier are optional; the server responds with
    /// `saved: false, tin_required: true` when TIN is omitted so the
    /// UI can prompt for it later.
    func saveTaxProfile(_ request: SaveTaxProfileRequest) async throws -> SuccessDataResponse<SaveTaxProfileData> {
        try await service.httpRequest(
            url: url(.saveTaxProfile),
            method: .post,
            body: request
        )
    }
}
