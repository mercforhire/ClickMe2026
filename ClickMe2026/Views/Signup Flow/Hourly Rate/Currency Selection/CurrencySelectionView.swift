//
//  CurrencySelectionView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Currency Model

struct CurrencyOption: Identifiable {
    let id = UUID()
    let symbol: String // e.g. "$", "€", "Fr"
    let code: String // e.g. "USD"
    let name: String // e.g. "United States Dollar"

    static let all: [CurrencyOption] = [
        CurrencyOption(symbol: "$",  code: "USD", name: "United States Dollar"),
        CurrencyOption(symbol: "€",  code: "EUR", name: "Euro"),
        CurrencyOption(symbol: "£",  code: "GBP", name: "British Pound"),
        CurrencyOption(symbol: "¥",  code: "JPY", name: "Japanese Yen"),
        CurrencyOption(symbol: "$",  code: "CAD", name: "Canadian Dollar"),
        CurrencyOption(symbol: "$",  code: "AUD", name: "Australian Dollar"),
        CurrencyOption(symbol: "Fr", code: "CHF", name: "Swiss Franc"),
        CurrencyOption(symbol: "¥",  code: "CNY", name: "Chinese Yuan"),
        CurrencyOption(symbol: "kr", code: "SEK", name: "Swedish Krona"),
    ]
}

// MARK: - Currency Selection View

struct ClickMeCurrencySelectionView: View {

    @StateObject private var viewModel: CurrencySelectionViewModel

    @Environment(\.dismiss) private var dismiss

    var onSelect: (CurrencyOption) -> Void
    var onCancel: () -> Void

    // MARK: Design tokens

    private let bg          = Color(red: 0.085, green: 0.090, blue: 0.100)
    private let searchBg    = Color(red: 0.150, green: 0.155, blue: 0.165)
    private let rowSelected = Color(red: 0.165, green: 0.745, blue: 0.450)
    private let brandGreen  = Color(red: 0.165, green: 0.745, blue: 0.450)
    private let onSurface   = Color.white
    private let onSurfaceVar = Color(red: 0.620, green: 0.640, blue: 0.665)
    private let onPrimary   = Color.black

    // MARK: Init

    init(
        viewModel: CurrencySelectionViewModel = CurrencySelectionViewModel(),
        onSelect: @escaping (CurrencyOption) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSelect = onSelect
        self.onCancel = onCancel
    }

    /// Convenience: build the VM directly from an initial currency code.
    init(
        initialCurrency: String,
        onSelect: @escaping (CurrencyOption) -> Void = { _ in },
        onCancel: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: CurrencySelectionViewModel(initialCurrency: initialCurrency),
            onSelect: onSelect,
            onCancel: onCancel
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                title
                    .padding(.top, 16)
                    .padding(.bottom, 18)

                searchBar
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                currencyList

                bottomActions
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Title

    private var title: some View {
        Text("Select Currency")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(onSurface)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(onSurfaceVar)

            TextField("", text: $viewModel.searchText)
                .placeholder(when: viewModel.searchText.isEmpty) {
                    Text("Search currency")
                        .foregroundColor(onSurfaceVar)
                        .font(.system(size: 15, design: .rounded))
                }
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(onSurface)
                .tint(brandGreen)
                .autocapitalization(.allCharacters)
                .disableAutocorrection(true)

            if !viewModel.searchText.isEmpty {
                Button { viewModel.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(onSurfaceVar.opacity(0.60))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(searchBg)
        )
    }

    // MARK: - Currency list

    private var currencyList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.filtered) { item in
                    currencyRow(item)
                }
            }
        }
    }

    private func currencyRow(_ item: CurrencyOption) -> some View {
        let isSelected = viewModel.pendingSelect == item.code

        return Button {
            withAnimation(.easeInOut(duration: 0.18)) {
                viewModel.selectRow(item.code)
            }
        } label: {
            HStack(spacing: 0) {
                Text(item.symbol)
                    .font(.system(size: 18, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? onPrimary : onSurface)
                    .frame(width: 36, alignment: .leading)
                    .padding(.leading, 20)

                Text(item.code)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? onPrimary : onSurface)

                Spacer()

                Text(item.name)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(isSelected ? onPrimary.opacity(0.85) : onSurfaceVar)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(onPrimary)
                        .padding(.leading, 12)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.trailing, 20)
            .frame(height: 56)
            .background(isSelected ? rowSelected : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isSelected)
    }

    // MARK: - Bottom actions

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                onCancel()
                dismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(onSurface)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule().fill(searchBg)
                    )
            }
            .buttonStyle(CurrencyScale())

            Button {
                if let item = viewModel.pendingOption {
                    onSelect(item)
                    dismiss()
                }
            } label: {
                Text("Select")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(onPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule().fill(brandGreen)
                    )
            }
            .buttonStyle(CurrencyScale())
        }
    }
}

// MARK: - Button style

private struct CurrencyScale: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Currency Selection") {
    ClickMeCurrencySelectionView()
        .preferredColorScheme(.dark)
}

#Preview("Currency — USD selected") {
    ClickMeCurrencySelectionView(initialCurrency: "USD")
        .preferredColorScheme(.dark)
}
