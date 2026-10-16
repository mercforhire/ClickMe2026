//
//  ClientBookingNoteView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Client-side private note on a specific booking. Loaded on appear
/// from `GET /client/bookings/:id/note`; saved via
/// `POST /client/bookings/:id/note`.
///
/// Displayed as a simple text editor with a "Save" button in the nav
/// bar — matches the low-ceremony pattern the rest of the settings
/// screens use.
struct ClientBookingNoteView: View {
    @StateObject private var viewModel: ClientBookingNoteViewModel

    /// Seed the header. Injected because the note endpoint doesn't
    /// return the expert / topic — we're just showing what the note
    /// is for on the same card the user came from.
    let expertName: String
    let topic: String
    let dateLabel: String

    @FocusState private var isFocused: Bool

    init(
        bookingId: UUID,
        expertName: String,
        topic: String,
        dateLabel: String
    ) {
        _viewModel = StateObject(wrappedValue: ClientBookingNoteViewModel(bookingId: bookingId))
        self.expertName = expertName
        self.topic = topic
        self.dateLabel = dateLabel
    }

    var body: some View {
        ZStack {
            MyBookingsBrand.bg.ignoresSafeArea()
            content
        }
        .task { await viewModel.load() }
        .navigationTitle("My Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(MyBookingsBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
        }
        .alert(
            "Couldn't save note",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .keyboardDismissToolbar()
    }

    // MARK: - Content router

    @ViewBuilder
    private var content: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            loadingContent
        case .failed(let message):
            errorContent(message: message)
        case .loaded:
            loadedContent
        }
    }

    private var loadedContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header
                editor
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(expertName)
                .font(.brand(.title3, weight: .bold))
                .foregroundColor(MyBookingsBrand.onSurface)
            Text(topic)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
            Text(dateLabel)
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(MyBookingsBrand.onSurfaceVar.opacity(0.7))
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(MyBookingsBrand.cardBg)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(MyBookingsBrand.cardBorder, lineWidth: 1))

            if viewModel.noteText.isEmpty && !isFocused {
                Text("Jot down your thoughts about this session — only you'll see this.")
                    .font(.brand(.subheadline))
                    .foregroundColor(MyBookingsBrand.onSurfaceVar.opacity(0.55))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $viewModel.noteText)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .font(.brand(.subheadline))
                .foregroundColor(MyBookingsBrand.onSurface)
                .tint(MyBookingsBrand.brandGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(minHeight: 260)
        }
    }

    // MARK: - Save button

    @ViewBuilder
    private var saveButton: some View {
        if viewModel.isSaving {
            ProgressView().controlSize(.small).tint(MyBookingsBrand.onSurface)
        } else if viewModel.didSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(MyBookingsBrand.brandGreen)
                .transition(.opacity)
        } else {
            Button {
                Task { await viewModel.save() }
            } label: {
                Text("Save")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(viewModel.hasChanges ? MyBookingsBrand.brandGreen : MyBookingsBrand.onSurfaceVar.opacity(0.45))
            }
            .disabled(!viewModel.hasChanges)
        }
    }

    // MARK: - Loading / error

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(MyBookingsBrand.onSurface)
            Text("Loading note…")
                .font(.brand(.caption))
                .foregroundColor(MyBookingsBrand.onSurfaceVar)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(MyBookingsBrand.onSurface.opacity(0.6))
            Text("Couldn't load note")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(MyBookingsBrand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(MyBookingsBrand.onSurface.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button {
                Task {
                    viewModel.loadState = .idle
                    await viewModel.load()
                }
            } label: {
                Text("Retry")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
