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

    /// The expert's own topics (from `GET /expert/topics`).
    @Published var topics: [ExpertTopicItem]

    // MARK: UI state

    @Published var loadState: LoadState

    // MARK: Sheet state
    @Published var editingTopic: ExpertTopicItem?
    @Published var showTopicEditor: Bool

    /// Non-fatal error surfaced from any topic mutation (create/update/delete).
    @Published var apiError: String?

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: Init

    /// Runtime init — data hydrates on `load()`.
    init(api: ClickMeAPI = .shared) {
        self.topics = []
        self.loadState = .idle
        self.editingTopic = nil
        self.showTopicEditor = false
        self.apiError = nil
        self.api = api
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        topics: [ExpertTopicItem] = TopicsSetupViewModel.sampleTopics
    ) -> TopicsSetupViewModel {
        let vm = TopicsSetupViewModel()
        vm.topics = topics
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Fetches `/expert/topics`. Idempotent — skips when already loaded so
    /// preview seeds aren't clobbered.
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
            let topicsResponse = try await api.getMyTopics()
            topics = topicsResponse.data.topics
            loadState = .loaded
        } catch {
            loadState = .failed(error.userMessage)
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
    /// depending on whether we're creating or editing. Returns the
    /// server error message on failure so the editor can display it
    /// inline (and stay open for the user to correct + retry). Returns
    /// nil on success — the editor then dismisses itself.
    ///
    /// Historically this method sank the error into `apiError` and also
    /// called `dismissTopicEditor()` on success; the alert-on-
    /// fullScreenCover-content proved unreliable in SwiftUI (would only
    /// fire after the cover had dismissed), so we now hand the message
    /// back to the caller.
    @discardableResult
    func saveTopic(
        title: String,
        description: String?,
        durationMins: Int,
        hourlyRateAmount: Int,
        currency: String,
        iconSlug: String?,
        expertiseTagIds: [String]
    ) async -> String? {
        do {
            if let existing = editingTopic {
                let body = UpdateExpertTopicRequest(
                    title: title,
                    description: description,
                    durationMins: durationMins,
                    hourlyRate: .init(amount: hourlyRateAmount, currency: currency),
                    isFree: false,
                    iconSlug: iconSlug,
                    expertiseTagIds: expertiseTagIds
                )
                let updated = try await api.updateMyTopic(id: existing.id, body).data.topic
                if let idx = topics.firstIndex(where: { $0.id == existing.id }) {
                    topics[idx] = updated
                }
            } else {
                let body = CreateExpertTopicRequest(
                    title: title,
                    description: description,
                    durationMins: durationMins,
                    hourlyRate: .init(amount: hourlyRateAmount, currency: currency),
                    isFree: false,
                    iconSlug: iconSlug,
                    expertiseTagIds: expertiseTagIds
                )
                let created = try await api.createMyTopic(body).data.topic
                topics.append(created)
            }
            return nil
        } catch {
            return error.userMessage
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

    // MARK: - Preview data

    /// Shape-faithful sample topics for `#Preview`.
    static let sampleTopics: [ExpertTopicItem] = [
        ExpertTopicItem(
            id: UUID(),
            title: "Go-to-Market Execution",
            durationMins: 60,
            description: nil,
            price: .init(amount: 25000, currency: "USD", isFree: false, label: "$250"),
            hourlyRate: .init(amount: 25000, currency: "USD"),
            iconSlug: "business",
            expertiseTags: nil
        ),
        ExpertTopicItem(
            id: UUID(),
            title: "Content Authority Building",
            durationMins: 60,
            description: nil,
            price: .init(amount: 18000, currency: "USD", isFree: false, label: "$180"),
            hourlyRate: .init(amount: 18000, currency: "USD"),
            iconSlug: "marketing",
            expertiseTags: nil
        ),
    ]
}
