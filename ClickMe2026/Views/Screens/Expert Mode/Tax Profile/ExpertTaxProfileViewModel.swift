//
//  ExpertTaxProfileViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Backs the "Tax & Payout Info" screen — reads the current tax
/// profile via `GET /expert/tax-profile` (masked; TIN is never sent
/// back) and saves via `POST /expert/tax-profile`.
///
/// Two branches on save:
///  * TIN provided → server persists everything, `saved: true`.
///  * TIN omitted → server responds `saved: false, tin_required:
///    true`; we surface the message and keep the fields around so
///    the user can add TIN later.
@MainActor
final class ExpertTaxProfileViewModel: ObservableObject {

    // MARK: Load state

    @Published var loadState: LoadState = .idle

    // MARK: Form fields (bound to the view)

    @Published var legalName: String = ""

    @Published var addressLine1: String = ""
    @Published var addressLine2: String = ""
    @Published var city: String = ""
    @Published var region: String = ""
    @Published var postalCode: String = ""
    /// Defaults to CA — the only country Stripe Connect supports in v1
    /// per §3.1 of the integration doc. Kept as a plain string so we
    /// don't need a picker until other countries land.
    @Published var country: String = "CA"

    /// `YYYY-MM-DD`.
    @Published var dob: String = ""

    /// Sensitive — never comes back on GET. Only sent on save; local
    /// state clears after a successful persist so the field doesn't
    /// linger in memory longer than needed.
    @Published var tin: String = ""

    @Published var financialAccountIdentifier: String = ""

    // MARK: Server-derived state

    /// True when the server has a TIN on file. Drives the "TIN saved"
    /// pill on the read screen — the raw value is never displayed.
    @Published var tinOnFile: Bool = false

    // MARK: Save state

    @Published var isSaving: Bool = false
    /// Alert message shown after save — success or failure. Simpler than
    /// a two-alert dance; the semantics are already conveyed by the
    /// message text.
    @Published var saveMessage: String?
    @Published var saveError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(api: ClickMeAPI = .shared) {
        self.api = api
    }

    // MARK: - Load

    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        loadState = .loading
        do {
            let response = try await api.getTaxProfile()
            apply(response.data)
            loadState = .loaded
        } catch {
            #if DEBUG
            // Surface the *actual* decoding / http error so we can tell
            // "endpoint 404" from "field mismatch" from "empty object"
            // without adding a request logger. Trim later.
            print("tax-profile: load failed — \(error)")
            #endif
            loadState = .failed(error.userMessage)
        }
    }

    private func apply(_ data: TaxProfileData) {
        legalName = data.legalName ?? ""
        dob = data.dob ?? ""
        tinOnFile = data.tinOnFile ?? false
        financialAccountIdentifier = data.financialAccountIdentifier ?? ""

        if let address = data.address {
            addressLine1 = address.line1 ?? ""
            addressLine2 = address.line2 ?? ""
            city = address.city ?? ""
            region = address.region ?? ""
            postalCode = address.postalCode ?? ""
            // Preserve the CA default when the server omits country so
            // the picker doesn't render blank.
            country = address.country ?? country
        }
    }

    // MARK: - Save

    /// Simple client-side gate on required fields. Server does the
    /// canonical validation; this just spares an obvious round-trip.
    var canSave: Bool {
        !legalName.trimmingCharacters(in: .whitespaces).isEmpty
            && !dob.isEmpty
            && !addressLine1.trimmingCharacters(in: .whitespaces).isEmpty
            && !city.trimmingCharacters(in: .whitespaces).isEmpty
            && !region.trimmingCharacters(in: .whitespaces).isEmpty
            && !postalCode.trimmingCharacters(in: .whitespaces).isEmpty
            && !country.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func save() async {
        guard canSave, !isSaving else { return }
        isSaving = true
        defer { isSaving = false }

        let trimmedTIN = tin.trimmingCharacters(in: .whitespaces)
        let request = SaveTaxProfileRequest(
            legalName: legalName.trimmingCharacters(in: .whitespaces),
            address: TaxProfileAddress(
                line1: addressLine1.trimmingCharacters(in: .whitespaces),
                line2: addressLine2.trimmingCharacters(in: .whitespaces).nilIfEmpty,
                city: city.trimmingCharacters(in: .whitespaces),
                region: region.trimmingCharacters(in: .whitespaces),
                postalCode: postalCode.trimmingCharacters(in: .whitespaces),
                country: country.trimmingCharacters(in: .whitespaces).uppercased()
            ),
            dob: dob,
            tin: trimmedTIN.isEmpty ? nil : trimmedTIN,
            financialAccountIdentifier: financialAccountIdentifier
                .trimmingCharacters(in: .whitespaces)
                .nilIfEmpty
        )

        do {
            let response = try await api.saveTaxProfile(request)
            if response.data.saved {
                tinOnFile = true
                tin = ""  // clear sensitive value from memory once persisted
                saveMessage = response.data.message ?? "Tax profile saved."
            } else {
                // Deferred save — server didn't persist because TIN was
                // omitted. Surface the message verbatim; TIN stays in
                // the field so the user can add it and re-save.
                saveMessage = response.data.message
                    ?? "Add a TIN to complete your tax profile."
            }
        } catch {
            saveError = error.userMessage
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
