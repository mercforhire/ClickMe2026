//
//  ExpertBookingNoteView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Expert-side private note on a specific past session. Mirrors the
/// client's `ClientBookingNoteView` — same text editor, same nav-bar
/// Save button, same header. Only difference is which endpoint the VM
/// fires: `GET`/`POST /bookings/:id/note` (expert-scoped route).
struct ExpertBookingNoteView: View {
    @StateObject private var viewModel: ExpertBookingNoteViewModel

    /// Seed the header. Injected because the note endpoint doesn't
    /// return the client / topic — we're just showing what the note
    /// is for on the same card the user came from.
    let clientName: String
    let topic: String
    let dateLabel: String

    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showDiscardPrompt = false

    init(
        bookingId: UUID,
        clientName: String,
        topic: String,
        dateLabel: String
    ) {
        _viewModel = StateObject(wrappedValue: ExpertBookingNoteViewModel(bookingId: bookingId))
        self.clientName = clientName
        self.topic = topic
        self.dateLabel = dateLabel
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()
            content
                .alert("Discard changes?", isPresented: $showDiscardPrompt) {
                    Button("Keep editing", role: .cancel) {}
                    Button("Discard", role: .destructive) { dismiss() }
                } message: {
                    Text("Your changes to this note won't be saved.")
                }
        }
        // The interactive pop is always disabled so a swipe can never discard unsaved edits;
        // the Back button is the only exit (D-19 amendment, user decision 2026-11-16).
        .background(BookingRequestSentPopGestureLock())
        .navigationBarBackButtonHidden(true)
        .task { await viewModel.load() }
        .navigationTitle("My Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                backButton
            }
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
                VStack(spacing: 4) {
                    editor
                    counter
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(clientName)
                .font(.brand(.title3, weight: .bold))
                .foregroundColor(Brand.onSurface)
            Text(topic)
                .font(.brand(.subheadline, weight: .regular))
                .foregroundColor(Brand.onSurfaceVariant)
            Text(dateLabel)
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(Brand.onSurfaceVariant.opacity(0.7))
        }
    }

    private var editor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Brand.outlineVariant, lineWidth: 1))

            if viewModel.noteText.isEmpty && !isFocused {
                Text("Jot down your thoughts about this session — only you'll see this.")
                    .font(.brand(.subheadline))
                    .foregroundColor(Brand.onSurfaceVariant.opacity(0.55))
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }

            TextEditor(text: Binding(
                get: { viewModel.noteText },
                set: { viewModel.updateNote($0) }
            ))
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .font(.brand(.subheadline))
                .foregroundColor(Brand.onSurface)
                .tint(Brand.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(minHeight: 260)
        }
    }

    // MARK: - Back (EXP-16, D-19)

    /// Pops at once when nothing is unsaved; otherwise asks `Discard changes?` first.
    private var backButton: some View {
        Button {
            if viewModel.needsDiscardPrompt {
                showDiscardPrompt = true
            } else {
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.body.weight(.semibold))
                .foregroundColor(Brand.onSurface)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
    }

    // MARK: - Counter (EXP-16, D-19)

    /// Shown from 4,500 units; reserves no space before that.
    @ViewBuilder
    private var counter: some View {
        if viewModel.showsCounter {
            Text(ExpertBookingNoteViewModel.counterText(length: viewModel.noteLength))
                .font(.brand(.caption, weight: .regular))
                .foregroundColor(viewModel.noteLength == ExpertBookingNoteViewModel.noteLimit ? Brand.error : Brand.onSurfaceMuted)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityLabel("\(viewModel.noteLength) of 5,000 characters")
        }
    }

    // MARK: - Save button

    @ViewBuilder
    private var saveButton: some View {
        if viewModel.isSaving {
            ProgressView().controlSize(.small).tint(Brand.onSurface)
        } else if viewModel.didSave {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Brand.primary)
                .transition(.opacity)
        } else {
            Button {
                Task { await viewModel.save() }
            } label: {
                Text("Save")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(viewModel.hasChanges ? Brand.primary : Brand.onSurfaceVariant.opacity(0.45))
            }
            .disabled(!viewModel.hasChanges)
        }
    }

    // MARK: - Loading / error

    private var loadingContent: some View {
        VStack(spacing: 12) {
            ProgressView().tint(Brand.onSurface)
            Text("Loading note…")
                .font(.brand(.caption))
                .foregroundColor(Brand.onSurfaceVariant)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorContent(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title.weight(.light))
                .foregroundColor(Brand.onSurface.opacity(0.6))
            Text("Couldn't load note")
                .font(.brand(.subheadline, weight: .semibold))
                .foregroundColor(Brand.onSurface)
            Text(message)
                .font(.brand(.caption))
                .foregroundColor(Brand.onSurface.opacity(0.6))
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
                    .foregroundColor(Brand.onPrimary)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Brand.primary))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
