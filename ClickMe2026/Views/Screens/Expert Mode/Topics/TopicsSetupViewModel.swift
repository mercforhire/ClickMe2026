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

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

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

    // MARK: Save state (expertise tags patch)
    @Published var isSaving: Bool
    @Published var didSave: Bool
    /// Non-fatal error surfaced from any mutation (create/update/delete/tag save).
    @Published var apiError: String?

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
        self.isSaving = false
        self.didSave = false
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
            loadState = .failed(Self.errorMessage(for: error))
            return
        }

        do {
            let topicsResponse = try await api.getMyTopics()
            topics = topicsResponse.data.topics
            hydrateSelectedTags()
            loadState = .loaded
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
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
    /// always succeed.
    func toggleTag(_ tag: ExpertiseTagItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedTagIds.contains(tag.id) {
                selectedTagIds.remove(tag.id)
            } else if selectedTagIds.count < maxTagSelection {
                selectedTagIds.insert(tag.id)
            }
        }
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
        freeConsultationMinutes: Int?
    ) async {
        apiError = nil
        do {
            if let existing = editingTopic {
                let body = UpdateExpertTopicRequest(
                    title: title,
                    description: description,
                    durationMins: durationMins,
                    hourlyRate: .init(amount: hourlyRateAmount, currency: currency),
                    freeConsultationMinutes: freeConsultationMinutes
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
                    freeConsultationMinutes: freeConsultationMinutes
                )
                let created = try await api.createMyTopic(body).data
                topics.append(created)
            }
            dismissTopicEditor()
        } catch {
            apiError = Self.errorMessage(for: error)
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
            apiError = Self.errorMessage(for: error)
        }
    }

    // MARK: - Save (expertise tags → PATCH /expert/profile)

    /// Sends the currently-selected tags via `PATCH /expert/profile`.
    /// First selected tag is flagged `is_primary`. On success flashes the
    /// "Saved!" state briefly; on failure surfaces `apiError`.
    func save() async {
        guard !isSaving, !didSave else { return }

        withAnimation { isSaving = true }
        defer { isSaving = false }

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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { didSave = true }
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { didSave = false }
        } catch {
            apiError = Self.errorMessage(for: error)
        }
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

    /// Shape-faithful sample topics for `#Preview`.
    static let sampleTopics: [ExpertTopicItem] = [
        ExpertTopicItem(
            id: UUID(),
            title: "Go-to-Market Execution",
            durationMins: 60,
            description: nil,
            price: .init(amount: 25000, currency: "USD", isFree: false, label: "$250 / hr"),
            hourlyRate: .init(amount: 25000, currency: "USD"),
            freeConsultationMinutes: 15
        ),
        ExpertTopicItem(
            id: UUID(),
            title: "Content Authority Building",
            durationMins: 60,
            description: nil,
            price: .init(amount: 18000, currency: "USD", isFree: false, label: "$180 / hr"),
            hourlyRate: .init(amount: 18000, currency: "USD"),
            freeConsultationMinutes: nil
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
