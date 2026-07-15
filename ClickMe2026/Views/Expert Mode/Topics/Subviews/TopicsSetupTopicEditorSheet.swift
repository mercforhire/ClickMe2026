//
//  TopicsSetupTopicEditorSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupTopicEditorSheet: View {
    let topic: ExpertTopic?
    let availableAreas: [String]
    let onSave: (ExpertTopic) -> Void
    let onDismiss: () -> Void

    @State private var expertiseArea: String
    @State private var title: String
    @State private var rate: String
    @State private var hasFreeConsult: Bool
    @State private var freeConsultMinutes: String
    @State private var showError = false

    init(
        topic: ExpertTopic?,
        availableAreas: [String],
        onSave: @escaping (ExpertTopic) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.topic = topic
        self.availableAreas = availableAreas
        self.onSave = onSave
        self.onDismiss = onDismiss
        _expertiseArea = State(initialValue: topic?.expertiseArea ?? availableAreas.first ?? "")
        _title = State(initialValue: topic?.title ?? "")
        _rate = State(initialValue: topic.map { String($0.hourlyRate) } ?? "")
        _hasFreeConsult = State(initialValue: topic?.freeConsultationMinutes != nil)
        _freeConsultMinutes = State(initialValue: topic?.freeConsultationMinutes.map { String($0) } ?? "15")
    }

    var body: some View {
        ZStack {
            TopicsSetupTheme.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(topic == nil ? "Add Topic" : "Edit Topic")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(TopicsSetupTheme.onSurface)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)

                    // Expertise area picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Expertise Area")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(TopicsSetupTheme.onSurfaceVariant)

                        Menu {
                            ForEach(availableAreas, id: \.self) { area in
                                Button(area) { expertiseArea = area }
                            }
                        } label: {
                            HStack {
                                Text(expertiseArea.isEmpty ? "Select area" : expertiseArea)
                                    .foregroundColor(expertiseArea.isEmpty ? TopicsSetupTheme.onSurfaceVariant : TopicsSetupTheme.onSurface)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                            }
                            .font(.system(size: 15))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TopicsSetupTheme.cardBg)
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(TopicsSetupTheme.outlineVariant.opacity(0.6), lineWidth: 1))
                            )
                        }
                    }

                    sheetField(label: "Topic Title", placeholder: "e.g. Go-to-Market Execution", text: $title, keyboard: .default)

                    sheetField(label: "Hourly Rate ($)", placeholder: "e.g. 150", text: $rate, keyboard: .numberPad)

                    // Free consultation
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Offer free consultation")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(TopicsSetupTheme.onSurface)
                            Spacer()
                            Toggle("", isOn: $hasFreeConsult)
                                .labelsHidden()
                                .tint(TopicsSetupTheme.primaryContainer)
                        }
                        if hasFreeConsult {
                            sheetField(label: "Duration (minutes)", placeholder: "e.g. 15", text: $freeConsultMinutes, keyboard: .numberPad)
                        }
                    }

                    if showError {
                        Text("Please fill in all required fields with valid values.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(TopicsSetupTheme.error)
                            .transition(.opacity)
                    }

                    HStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(TopicsSetupTheme.onSurface)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(TopicsSetupTheme.surfaceHigh)
                                )
                        }

                        Button { attemptSave() } label: {
                            Text("Save")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(TopicsSetupTheme.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(TopicsSetupTheme.primary)
                                        .shadow(color: TopicsSetupTheme.primary.opacity(0.3), radius: 6, x: 0, y: 2)
                                )
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(24)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showError)
        .animation(.easeInOut(duration: 0.2), value: hasFreeConsult)
    }

    private func attemptSave() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty,
              !expertiseArea.isEmpty,
              let rateVal = Int(rate.trimmingCharacters(in: .whitespaces))
        else {
            withAnimation { showError = true }
            return
        }
        var minutes: Int? = nil
        if hasFreeConsult {
            guard let m = Int(freeConsultMinutes.trimmingCharacters(in: .whitespaces)), m > 0 else {
                withAnimation { showError = true }
                return
            }
            minutes = m
        }
        let saved = ExpertTopic(
            id: topic?.id ?? UUID(),
            expertiseArea: expertiseArea,
            title: trimmedTitle,
            hourlyRate: rateVal,
            freeConsultationMinutes: minutes
        )
        onSave(saved)
    }

    private func sheetField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(TopicsSetupTheme.onSurfaceVariant)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 15))
                .foregroundColor(TopicsSetupTheme.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(TopicsSetupTheme.cardBg)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(TopicsSetupTheme.outlineVariant.opacity(0.6), lineWidth: 1))
                )
        }
    }
}
