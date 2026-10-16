//
//  ClientBookingNoteViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// State + IO for the client's private note on a specific past booking.
/// Fetch on appear via `GET /client/bookings/:id/note`, upsert on save
/// via `POST /client/bookings/:id/note`. `note` is nil in the response
/// when the client hasn't written one yet — we display an empty field.
@MainActor
final class ClientBookingNoteViewModel: ObservableObject {

    /// Server booking UUID.
    let bookingId: UUID

    // MARK: Editable state
    @Published var noteText: String = ""

    // MARK: Load state
    @Published var loadState: LoadState = .idle

    /// True while `POST /note` is in flight; drives the Save button
    /// spinner + disables it against double-tap.
    @Published var isSaving: Bool = false

    /// Briefly flips true after a successful save so the view can show
    /// a checkmark / toast. Auto-clears after a short delay.
    @Published var didSave: Bool = false

    /// Non-fatal error surfaced by the network layer. Bound to a
    /// system alert.
    @Published var errorMessage: String?

    /// Snapshot of the last successfully-loaded / saved text — used to
    /// disable the Save button when nothing has changed.
    private var lastPersisted: String = ""

    /// True when the current `noteText` differs from the last known
    /// server state. Drives the Save button's enabled state.
    var hasChanges: Bool { noteText != lastPersisted }

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

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
            let response = try await api.getClientBookingNote(id: bookingId)
            let text = response.data.note ?? ""
            noteText = text
            lastPersisted = text
            loadState = .loaded
        } catch {
            // Treat "no note yet" as an empty field rather than a
            // failed load. The server returns 404 in the uniform-
            // ambiguous case, but also for genuinely-missing rows —
            // if the caller is on this screen they're the client on
            // the booking, so 404 here just means "not written yet."
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

    /// POST the current `noteText`. Guarded against double-fire and
    /// no-ops when there's nothing to save.
    func save() async {
        guard !isSaving, hasChanges else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            let response = try await api.createClientBookingNote(id: bookingId, note: noteText)
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
