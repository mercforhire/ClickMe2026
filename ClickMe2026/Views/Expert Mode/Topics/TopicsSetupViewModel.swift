//
//  TopicsSetupViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class TopicsSetupViewModel {
    // MARK: Expertise areas (pill tags)

    var expertiseAreas: [String]

    // MARK: Topics

    var topics: [ExpertTopic]

    // MARK: Global settings

    var globalFreeConsult: Bool
    var inAppVoiceEnabled: Bool
    var skypeZoomEnabled: Bool

    // MARK: Sheet state

    var editingTopic: ExpertTopic?
    var showTopicEditor: Bool = false
    var showAddExpertise: Bool = false

    // MARK: Save state

    var isSaving: Bool = false
    var didSave: Bool = false

    // MARK: Init

    init(
        expertiseAreas: [String] = [
            "Business Strategy",
            "Marketing",
        ],
        topics: [ExpertTopic] = [
            ExpertTopic(
                expertiseArea: "Business Strategy",
                title: "Go-to-Market Execution",
                hourlyRate: 250,
                freeConsultationMinutes: 15
            ),
            ExpertTopic(
                expertiseArea: "Marketing",
                title: "Content Authority Building",
                hourlyRate: 180,
                freeConsultationMinutes: nil
            ),
        ],
        globalFreeConsult: Bool = true,
        inAppVoiceEnabled: Bool = true,
        skypeZoomEnabled: Bool = false
    ) {
        self.expertiseAreas = expertiseAreas
        self.topics = topics
        self.globalFreeConsult = globalFreeConsult
        self.inAppVoiceEnabled = inAppVoiceEnabled
        self.skypeZoomEnabled = skypeZoomEnabled
    }

    // MARK: Expertise intents

    func removeExpertiseArea(_ name: String) {
        withAnimation {
            expertiseAreas.removeAll { $0 == name }
            // Also drop topics that referenced it
            topics.removeAll { $0.expertiseArea == name }
        }
    }

    func openAddExpertise() {
        guard expertiseAreas.count < 5 else { return }
        showAddExpertise = true
    }

    func addExpertiseArea(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              !expertiseAreas.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }),
              expertiseAreas.count < 5
        else { return }
        withAnimation { expertiseAreas.append(trimmed) }
        showAddExpertise = false
    }

    func dismissAddExpertise() {
        showAddExpertise = false
    }

    // MARK: Topic intents

    func editTopic(_ topic: ExpertTopic) {
        editingTopic = topic
        showTopicEditor = true
    }

    func newTopic() {
        editingTopic = nil
        showTopicEditor = true
    }

    func saveTopic(_ updated: ExpertTopic) {
        if let existing = editingTopic,
           let idx = topics.firstIndex(where: { $0.id == existing.id })
        {
            topics[idx] = updated
        } else {
            topics.append(updated)
        }
        editingTopic = nil
        showTopicEditor = false
    }

    func deleteTopic(_ topic: ExpertTopic) {
        withAnimation { topics.removeAll { $0.id == topic.id } }
    }

    func dismissTopicEditor() {
        editingTopic = nil
        showTopicEditor = false
    }

    // MARK: Save

    func save() {
        guard !isSaving, !didSave else { return }
        withAnimation { isSaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self.isSaving = false
                self.didSave = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                withAnimation { self?.didSave = false }
            }
        }
    }
}
