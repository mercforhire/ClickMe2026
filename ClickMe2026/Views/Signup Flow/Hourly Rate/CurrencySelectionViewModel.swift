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

    // MARK: Form state
    @Published var searchText: String
    @Published var pendingSelect: String

    let options: [CurrencyOption]

    init(
        initialCurrency: String = "EUR",
        searchText: String = "",
        options: [CurrencyOption] = CurrencyOption.all
    ) {
        self.searchText = searchText
        self.pendingSelect = initialCurrency
        self.options = options
    }

    // MARK: Derived

    var filtered: [CurrencyOption] {
        guard !searchText.isEmpty else { return options }
        let q = searchText.lowercased()
        return options.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    var pendingOption: CurrencyOption? {
        options.first { $0.code == pendingSelect }
    }

    // MARK: Mutations

    func selectRow(_ code: String) {
        pendingSelect = code
    }

    func clearSearch() {
        searchText = ""
    }
}
