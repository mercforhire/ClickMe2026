//
//  PaymentMethodsViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class PaymentMethodsViewModel: ObservableObject {

    // MARK: List

    @Published var paymentMethods: [PaymentMethodItem] = []

    // MARK: Load state

    @Published var state: LoadState = .idle

    // MARK: Add-card (SetupIntent) state
    //
    // The view observes `pendingSetup` — when it flips from nil to a
    // populated value, the `PaymentMethodsSetupSheet` modifier presents
    // Stripe's PaymentSheet in setup mode. Cleared once the sheet
    // dismisses (success, cancel, or error).

    @Published var pendingSetup: PaymentMethodSetupData?
    @Published var isMintingSetupIntent: Bool = false

    // MARK: Row-scoped busy flags

    /// PM id currently being deleted, or nil. Drives the per-row spinner
    /// so we can visually mark the deleting row without disabling every
    /// other row on the screen.
    @Published var deletingId: String?

    /// PM id currently being promoted to default, or nil. Same UX rule
    /// as `deletingId`.
    @Published var settingDefaultId: String?

    // MARK: Alerts

    /// Surfaced to the view for a "Couldn't load" / "Couldn't add card"
    /// / "Couldn't remove" alert. Cleared when the alert dismisses.
    @Published var apiError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(
        paymentMethods: [PaymentMethodItem] = [],
        state: LoadState = .idle,
        api: ClickMeAPI = .shared
    ) {
        self.paymentMethods = paymentMethods
        self.state = state
        self.api = api
    }

    /// Preview seam — installs canned data as if a load had already
    /// succeeded. Used by the SwiftUI previews.
    static func previewSeed(
        paymentMethods: [PaymentMethodItem] = [
            PaymentMethodItem(id: "pm_visa_default",  brand: "visa",       last4: "4242", expMonth: 9,  expYear: 2028, isDefault: true),
            PaymentMethodItem(id: "pm_mastercard",    brand: "mastercard", last4: "8210", expMonth: 3,  expYear: 2027, isDefault: false),
        ]
    ) -> PaymentMethodsViewModel {
        PaymentMethodsViewModel(paymentMethods: paymentMethods, state: .loaded)
    }

    // MARK: - Load

    /// Fetches saved cards from `GET /me/payment-methods`. Idempotent —
    /// skips when already loaded so preview seeds aren't clobbered.
    func load() async {
        if case .loaded = state { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        state = .loading
        do {
            let response = try await api.getPaymentMethods()
            paymentMethods = response.data.paymentMethods
            state = .loaded
        } catch {
            state = .failed(error.userMessage)
        }
    }

    // MARK: - Add card (SetupIntent flow)

    /// Called by the view when the user taps "Add Payment Method".
    /// Mints a fresh SetupIntent and publishes it via `pendingSetup`;
    /// the sheet modifier reacts to that flip and presents Stripe's
    /// PaymentSheet in setup mode.
    ///
    /// No-op if a mint is already in flight (double-tap protection) or
    /// if a sheet is already up.
    func beginAddPaymentMethod() async {
        guard !isMintingSetupIntent, pendingSetup == nil else { return }
        isMintingSetupIntent = true
        defer { isMintingSetupIntent = false }
        do {
            let response = try await api.createPaymentMethodSetupIntent()
            pendingSetup = response.data
        } catch {
            apiError = error.userMessage
        }
    }

    /// Called by the sheet modifier after Stripe reports the SetupIntent
    /// completed successfully. Refreshes the list so the new card shows
    /// up, then clears `pendingSetup`.
    func completeAddPaymentMethod() async {
        pendingSetup = nil
        await forceLoad()
    }

    /// Called by the sheet modifier on user-cancel. Clears the pending
    /// intent without refetching — the list is unchanged.
    func cancelAddPaymentMethod() {
        pendingSetup = nil
    }

    /// Called by the sheet modifier on a Stripe failure. Surfaces the
    /// error and clears the pending intent.
    func failAddPaymentMethod(_ message: String) {
        pendingSetup = nil
        apiError = message
    }

    // MARK: - Delete

    /// Detaches a saved card. Optimistically removes it from the local
    /// list so the row animates out immediately; rolls back on failure.
    func deletePaymentMethod(_ item: PaymentMethodItem) async {
        guard deletingId == nil else { return }
        deletingId = item.id
        defer { deletingId = nil }

        let previous = paymentMethods
        withAnimation(.easeOut(duration: 0.2)) {
            paymentMethods.removeAll { $0.id == item.id }
        }
        do {
            _ = try await api.deletePaymentMethod(paymentMethodId: item.id)
        } catch {
            withAnimation(.easeOut(duration: 0.2)) { paymentMethods = previous }
            apiError = error.userMessage
        }
    }

    // MARK: - Set default

    /// Marks a card as the Stripe Customer's default. Optimistically
    /// flips the local `isDefault` flags (only one row true at a time)
    /// and rolls back on failure.
    func setDefault(_ item: PaymentMethodItem) async {
        guard settingDefaultId == nil, !item.isDefault else { return }
        settingDefaultId = item.id
        defer { settingDefaultId = nil }

        let previous = paymentMethods
        withAnimation(.easeOut(duration: 0.2)) {
            paymentMethods = paymentMethods.map {
                PaymentMethodItem(
                    id: $0.id,
                    brand: $0.brand,
                    last4: $0.last4,
                    expMonth: $0.expMonth,
                    expYear: $0.expYear,
                    isDefault: $0.id == item.id
                )
            }
        }
        do {
            _ = try await api.setDefaultPaymentMethod(paymentMethodId: item.id)
        } catch {
            withAnimation(.easeOut(duration: 0.2)) { paymentMethods = previous }
            apiError = error.userMessage
        }
    }
}
