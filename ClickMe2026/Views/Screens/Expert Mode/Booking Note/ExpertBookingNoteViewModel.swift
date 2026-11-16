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

    /// Whether leaving the screen must ask `Discard changes?`. A save in flight counts as
    /// unsaved until it succeeds, so Back during a save still asks.
    var needsDiscardPrompt: Bool { hasChanges || isSaving }

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

    // MARK: - Cap and counter (EXP-16, D-19)

    /// Server `noteSchema` limit (`z.string().max(5000)`), counted in UTF-16 code units.
    static let noteLimit = 5000

    /// The counter appears from this many UTF-16 units (Android `NOTE_COUNTER_FROM`).
    static let counterFrom = 4500

    /// Applies typed or pasted text, cut on a character boundary at `noteLimit` units
    /// so an emoji is never split and the server never rejects the note for length.
    func updateNote(_ raw: String) {
        noteText = UTF16Prefix.prefix(raw, limit: Self.noteLimit)
    }

    /// Current length in UTF-16 code units, the unit the server counts.
    var noteLength: Int { noteText.utf16.count }

    var showsCounter: Bool { noteLength >= Self.counterFrom }

    /// `{n} / 5,000` with integer grouping for `locale`, for example `4,731 / 5,000`.
    static func counterText(length: Int, locale: Locale = .current) -> String {
        "\(length.formatted(.number.locale(locale))) / \(noteLimit.formatted(.number.locale(locale)))"
    }

    /// A note that is empty after trimming spaces and newlines is sent as `""`, which
    /// clears it server-side. Any other text is sent exactly as typed, not trimmed.
    static func normalizedForSave(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : text
    }

    // MARK: - Save

    func save() async {
        guard !isSaving, hasChanges else { return }
        isSaving = true
        defer { isSaving = false }

        let typed = noteText
        let sent = Self.normalizedForSave(typed)

        do {
            _ = try await api.createBookingNote(id: bookingId, note: sent)
            // The persisted value is exactly what was sent. Text typed while the request
            // was in flight is kept and still counts as changed.
            lastPersisted = sent
            if noteText == typed { noteText = sent }
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
