//
//  CurrencySelectionViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class CurrencySelectionViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: State
    @Published var searchText: String
    @Published var pendingSelect: String
    @Published var options: [CurrencyItem] = []
    @Published var loadState: LoadState = .idle

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    init(
        initialCurrency: String = "USD",
        searchText: String = "",
        api: ClickMeAPI = .shared
    ) {
        self.searchText = searchText
        self.pendingSelect = initialCurrency
        self.api = api
    }

    /// Preview seam — installs canned options as if `getCurrencies` had
    /// succeeded.
    static func previewSeed(
        initialCurrency: String = "USD",
        options: [CurrencyItem] = CurrencySelectionViewModel.previewOptions
    ) -> CurrencySelectionViewModel {
        let vm = CurrencySelectionViewModel(initialCurrency: initialCurrency)
        vm.options = options
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded so preview seeds aren't
    /// clobbered.
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
            let response = try await api.getCurrencies()
            options = response.data.currencies
                .sorted { $0.code < $1.code }
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    // MARK: Derived

    var filtered: [CurrencyItem] {
        guard !searchText.isEmpty else { return options }
        let q = searchText.lowercased()
        return options.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var pendingOption: CurrencyItem? {
        options.first { $0.code == pendingSelect }
    }

    // MARK: Mutations

    func selectRow(_ code: String) {
        pendingSelect = code
    }

    func clearSearch() {
        searchText = ""
    }

    // MARK: - Error mapping

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    // MARK: - Preview data

    static let previewOptions: [CurrencyItem] = [
        CurrencyItem(code: "AUD", symbol: "$",  name: "Australian Dollar",     minorUnitDigits: 2),
        CurrencyItem(code: "CAD", symbol: "$",  name: "Canadian Dollar",       minorUnitDigits: 2),
        CurrencyItem(code: "CHF", symbol: "Fr", name: "Swiss Franc",           minorUnitDigits: 2),
        CurrencyItem(code: "CNY", symbol: "¥",  name: "Chinese Yuan",          minorUnitDigits: 2),
        CurrencyItem(code: "EUR", symbol: "€",  name: "Euro",                  minorUnitDigits: 2),
        CurrencyItem(code: "GBP", symbol: "£",  name: "British Pound",         minorUnitDigits: 2),
        CurrencyItem(code: "JPY", symbol: "¥",  name: "Japanese Yen",          minorUnitDigits: 0),
        CurrencyItem(code: "SEK", symbol: "kr", name: "Swedish Krona",         minorUnitDigits: 2),
        CurrencyItem(code: "USD", symbol: "$",  name: "United States Dollar",  minorUnitDigits: 2),
    ]
}
