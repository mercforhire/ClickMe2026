//
//  TopicsSetupViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class TopicsSetupViewModel: ObservableObject {


    // MARK: Server-sourced data

    /// Fixed taxonomy from `GET /meta/expertise-tags` — user picks up to 5.
    @Published var availableTags: [ExpertiseTagItem]
    /// Server UUIDs of the tags the expert currently has selected.
    @Published var selectedTagIds: Set<UUID>

    /// The expert's own topics (from `GET /expert/topics`).
    @Published var topics: [ExpertTopicItem]

    // MARK: UI state

    @Published var loadState: LoadState

    // MARK: Sheet state
    @Published var editingTopic: ExpertTopicItem?
    @Published var showTopicEditor: Bool

    // MARK: Auto-save state (expertise tags PATCH — debounced)

    /// True while a debounced auto-save is currently uploading. The nav
    /// bar shows a small spinner while this is true.
    @Published var isAutoSaving: Bool
    /// True immediately after a successful auto-save. Cleared as soon as
    /// the user flips another tag so the nav bar's checkmark hides.
    @Published var didAutoSave: Bool
    /// Non-fatal error surfaced from any mutation (create/update/delete/tag save).
    @Published var apiError: String?

    /// Task holding the pending debounce sleep + PATCH. Cancelled whenever
    /// a new tag flip comes in so only the trailing save fires.
    private var autoSaveTask: Task<Void, Never>?

    /// Debounce window between the last tag toggle and the actual PATCH.
    /// Long enough that rapid multi-toggle flips coalesce into one request,
    /// short enough that a single tap feels near-instant. Matches the
    /// notification-settings pattern.
    private let autoSaveDebounce: UInt64 = 800_000_000 // 0.8s

    // MARK: Dependencies

    private let api: ClickMeAPI

    /// Maximum number of expertise tags an expert may select. Matches the
    /// legacy UI cap.
    let maxTagSelection = 5

    // MARK: Init

    /// Runtime init — data hydrates on `load()`.
    init(api: ClickMeAPI = .shared) {
        self.availableTags = []
        self.selectedTagIds = []
        self.topics = []
        self.loadState = .idle
        self.editingTopic = nil
        self.showTopicEditor = false
        self.isAutoSaving = false
        self.didAutoSave = false
        self.apiError = nil
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        availableTags: [ExpertiseTagItem] = TopicsSetupViewModel.sampleTags,
        selectedTagIds: Set<UUID> = [],
        topics: [ExpertTopicItem] = TopicsSetupViewModel.sampleTopics
    ) -> TopicsSetupViewModel {
        let vm = TopicsSetupViewModel()
        vm.availableTags = availableTags
        vm.selectedTagIds = selectedTagIds.isEmpty
            ? Set(availableTags.prefix(2).map { $0.id })
            : selectedTagIds
        vm.topics = topics
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches `/meta/expertise-tags` + `/expert/topics` sequentially.
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

        // Sequential fetches — parallel `async let` decoding trips Swift 6's
        // main-actor-isolated Decodable check.
        do {
            let tagsResponse = try await api.getExpertiseTags()
            availableTags = tagsResponse.data.tags
                .sorted { $0.label.localizedCaseInsensitiveCompare($1.label) == .orderedAscending }
        } catch {
            loadState = .failed(error.userMessage)
            return
        }

        do {
            let topicsResponse = try await api.getMyTopics()
            topics = topicsResponse.data.topics
            hydrateSelectedTags()
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
        }
    }

    /// TODO: `selectedTagIds` should really come from `GET /expert/profile`
    /// so the expert's current tag selection round-trips. Until we wire
    /// that in this VM, leave the set empty on load — the user can pick
    /// again and Save will PATCH.
    private func hydrateSelectedTags() {
        // Intentionally no-op — awaiting profile-side hydration.
    }

    // MARK: - Expertise tag selection

    func isSelected(_ tag: ExpertiseTagItem) -> Bool {
        selectedTagIds.contains(tag.id)
    }

    /// Toggle a tag on/off. Respects the 5-tag cap on the way in — if the
    /// user is already at cap, ignore new selections silently. Removals
    /// always succeed. Fires a debounced auto-save so the change is
    /// persisted without requiring a Save button.
    func toggleTag(_ tag: ExpertiseTagItem) {
        var mutated = false
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedTagIds.contains(tag.id) {
                selectedTagIds.remove(tag.id)
                mutated = true
            } else if selectedTagIds.count < maxTagSelection {
                selectedTagIds.insert(tag.id)
                mutated = true
            }
        }
        if mutated { scheduleAutoSave() }
    }

    // MARK: - Topic CRUD

    /// Opens the editor sheet on an existing topic.
    func editTopic(_ topic: ExpertTopicItem) {
        editingTopic = topic
        showTopicEditor = true
    }

    /// Opens the editor sheet as "new topic".
    func newTopic() {
        editingTopic = nil
        showTopicEditor = true
    }

    func dismissTopicEditor() {
        editingTopic = nil
        showTopicEditor = false
    }

    /// Fires either `POST /expert/topics` or `PATCH /expert/topics/:id`
    /// depending on whether we're creating or editing. On success updates
    /// the in-memory list; on failure sets `apiError` for the alert.
    func saveTopic(
        title: String,
        description: String?,
        durationMins: Int,
        hourlyRateAmount: Int,
        currency: String,
        iconSlug: String?
    ) async {
        apiError = nil
        do {
            if let existing = editingTopic {
                let body = UpdateExpertTopicRequest(
                    title: title,
                    description: description,
                    durationMins: durationMins,
                    hourlyRate: .init(amount: hourlyRateAmount, currency: currency),
                    iconSlug: iconSlug
                )
                let updated = try await api.updateMyTopic(id: existing.id, body).data
                if let idx = topics.firstIndex(where: { $0.id == existing.id }) {
                    topics[idx] = updated
                }
            } else {
                let body = CreateExpertTopicRequest(
                    title: title,
                    description: description,
                    durationMins: durationMins,
                    hourlyRate: .init(amount: hourlyRateAmount, currency: currency),
                    iconSlug: iconSlug
                )
                let created = try await api.createMyTopic(body).data
                topics.append(created)
            }
            dismissTopicEditor()
        } catch {
            apiError = error.userMessage
        }
    }

    /// `DELETE /expert/topics/:id`. Server returns 409 with a message when
    /// the topic has active bookings — surface that message in the alert.
    func deleteTopic(_ topic: ExpertTopicItem) async {
        apiError = nil
        do {
            _ = try await api.deleteMyTopic(id: topic.id)
            topics.removeAll { $0.id == topic.id }
        } catch {
            apiError = error.userMessage
        }
    }

    // MARK: - Auto-save (expertise tags → PATCH /expert/profile)

    /// Cancels any pending PATCH and schedules a fresh one after the
    /// debounce window — rapid multi-toggle flips coalesce into a single
    /// trailing request. Called from `toggleTag(_:)` on every change.
    func scheduleAutoSave() {
        autoSaveTask?.cancel()
        // Hide the "saved" checkmark while the user is actively editing.
        if didAutoSave { didAutoSave = false }

        autoSaveTask = Task { [weak self] in
            guard let debounce = self?.autoSaveDebounce else { return }
            try? await Task.sleep(nanoseconds: debounce)
            guard !Task.isCancelled else { return }
            await self?.performAutoSave()
        }
    }

    /// Sends the currently-selected tags via `PATCH /expert/profile`.
    /// First selected tag is flagged `is_primary`. On success flashes the
    /// nav-bar "saved" checkmark until the next toggle; on failure
    /// surfaces `apiError`.
    private func performAutoSave() async {
        isAutoSaving = true
        defer { isAutoSaving = false }

        let ordered = availableTags
            .filter { selectedTagIds.contains($0.id) }
            .enumerated()
            .map { UpdateExpertProfileRequest.ExpertiseTag(
                tagId: $0.element.id.uuidString,
                isPrimary: $0.offset == 0
            ) }

        let body = UpdateExpertProfileRequest(
            personalInfo: nil,
            professionalDetails: nil,
            locationDetails: nil,
            languages: nil,
            expertiseTags: ordered,
            hourlyRate: nil
        )

        do {
            _ = try await api.updateExpertProfile(body)
            withAnimation(.easeOut(duration: 0.25)) { didAutoSave = true }
        } catch {
            apiError = error.userMessage
        }
    }

    // MARK: - Error mapping


    // MARK: - Preview data

    /// Shape-faithful sample topics for `#Preview`.
    static let sampleTopics: [ExpertTopicItem] = [
        ExpertTopicItem(
            id: UUID(),
            title: "Go-to-Market Execution",
            durationMins: 60,
            description: nil,
            price: .init(amount: 25000, currency: "USD", isFree: false, label: "$250 / hr"),
            hourlyRate: .init(amount: 25000, currency: "USD"),
            iconSlug: "business"
        ),
        ExpertTopicItem(
            id: UUID(),
            title: "Content Authority Building",
            durationMins: 60,
            description: nil,
            price: .init(amount: 18000, currency: "USD", isFree: false, label: "$180 / hr"),
            hourlyRate: .init(amount: 18000, currency: "USD"),
            iconSlug: "marketing"
        ),
    ]

    /// Shape-faithful sample tags for `#Preview`.
    static let sampleTags: [ExpertiseTagItem] = [
        ExpertiseTagItem(id: UUID(), label: "Business Strategy", categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Marketing",         categoryId: "business"),
        ExpertiseTagItem(id: UUID(), label: "Design",            categoryId: "creative"),
        ExpertiseTagItem(id: UUID(), label: "Engineering",       categoryId: "technology"),
        ExpertiseTagItem(id: UUID(), label: "Product Management", categoryId: "business"),
    ]
}
