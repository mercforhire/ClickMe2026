//
//  ExpertBookingNoteViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// State + IO for the expert's private note on a specific past session.
/// Mirrors the client-side `ClientBookingNoteViewModel` — same UX, same
/// load/save shape, only difference is which endpoint fires.
/// Backed by `GET /bookings/:id/note` (expert-scoped route on the
/// backend; the client uses `/client/bookings/:id/note`).
@MainActor
final class ExpertBookingNoteViewModel: ObservableObject {

    /// Server booking UUID.
    let bookingId: UUID

    // MARK: Editable state
    @Published var noteText: String = ""

    // MARK: Load state
    @Published var loadState: LoadState = .idle

    /// True while `POST /note` is in flight.
    @Published var isSaving: Bool = false

    /// Briefly flips true after a successful save so the view can
    /// animate a checkmark. Auto-clears after a short delay.
    @Published var didSave: Bool = false

    /// Non-fatal error surfaced by the network layer.
    @Published var errorMessage: String?

    /// Snapshot of the last successfully-loaded / saved text — drives
    /// the Save button's enabled state.
    private var lastPersisted: String = ""

    var hasChanges: Bool { noteText != lastPersisted }

    // MARK: Dependencies

    private let api: ClickMeAPI

    init(bookingId: UUID, api: ClickMeAPI = .shared) {
        self.bookingId = bookingId
        self.api = api
    }

    // MARK: - Load

    /// Fetches the current note. Idempotent — skips when already
    /// loaded so a re-appearance doesn't clobber unsaved edits.
    func load() async {
        if case .loaded = loadState { return }
        loadState = .loading
        do {
            let response = try await api.getBookingNote(id: bookingId)
            let text = response.data.note ?? ""
            noteText = text
            lastPersisted = text
            loadState = .loaded
        } catch {
            // Uniform-404 contract on the note endpoint — a 404 here
            // means either "no note yet" or "you don't own this
            // booking". Since only the expert on a booking reaches
            // this screen, treat 404 as an empty note.
            if case NetworkError.httpError(let status, _) = error, status == 404 {
                noteText = ""
                lastPersisted = ""
                loadState = .loaded
                return
            }
            loadState = .failed(error.userMessage)
        }
    }

    // MARK: - Save

    func save() async {
        guard !isSaving, hasChanges else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await api.createBookingNote(id: bookingId, note: noteText)
            lastPersisted = response.data.note ?? noteText
            withAnimation(.easeInOut(duration: 0.2)) { didSave = true }
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.2)) { self?.didSave = false }
                }
            }
        } catch {
            errorMessage = error.userMessage
        }
    }
}
