//
//  TopicEditorView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Full-screen editor for adding or editing an expert topic. The parent
/// screen (`TopicsSetupView`) presents this via `.fullScreenCover` and
/// performs the real POST/PATCH after `onSave` fires.
struct TopicEditorView: View {

    @StateObject private var viewModel: TopicEditorViewModel

    /// Fires once the user taps Save and inputs pass local validation.
    /// Args: (title, description, durationMins, hourlyRateAmountMinorUnits, currency, iconSlug?).
    let onSave: (String, String?, Int, Int, String, String?) -> Void
    let onDismiss: () -> Void

    // MARK: Init

    /// Runtime init — seeds the editor from an existing topic (edit mode)
    /// or nil (add mode).
    init(
        topic: ExpertTopicItem?,
        onSave: @escaping (String, String?, Int, Int, String, String?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TopicEditorViewModel(topic: topic))
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: TopicEditorViewModel,
        onSave: @escaping (String, String?, Int, Int, String, String?) -> Void = { _, _, _, _, _, _ in },
        onDismiss: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    // MARK: Body

    var body: some View {
        NavigationStack {
            ZStack {
                Brand.surface.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        iconPicker

                        editorField(
                            label: "Topic Title",
                            placeholder: "e.g. Go-to-Market Execution",
                            text: $viewModel.title,
                            keyboard: .default
                        )

                        editorField(
                            label: "Description (optional)",
                            placeholder: "What clients will get out of this session",
                            text: $viewModel.descriptionText,
                            keyboard: .default
                        )

                        editorField(
                            label: "Session Duration (minutes)",
                            placeholder: "e.g. 60",
                            text: $viewModel.durationMinutes,
                            keyboard: .numberPad
                        )

                        editorField(
                            label: "Hourly Rate ($)",
                            placeholder: "e.g. 150",
                            text: $viewModel.rate,
                            keyboard: .numberPad
                        )

                        if viewModel.showError {
                            Text("Please fill in all required fields with valid values.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Brand.error)
                                .transition(.opacity)
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Topic" : "Add Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel", action: onDismiss)
                        .foregroundColor(Brand.onSurface)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", action: attemptSave)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Brand.primary)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.showError)
        }
    }

    // MARK: - Icon picker

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Brand.onSurfaceVariant)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.pickableSlugs, id: \.self) { slug in
                        iconChip(slug: slug)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func iconChip(slug: String) -> some View {
        let selected = viewModel.isSelectedIcon(slug)
        return Button {
            viewModel.toggleIcon(slug)
        } label: {
            Image(systemName: CategoryIconMap.sfSymbol(forSlug: slug))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(selected ? Brand.primary : Brand.onSurfaceVariant)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? Brand.primary.opacity(0.12) : Brand.surfaceContainerLow)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    selected ? Brand.primary : Brand.outlineVariant.opacity(0.6),
                                    lineWidth: selected ? 1.5 : 1
                                )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func attemptSave() {
        guard let payload = viewModel.validate() else { return }
        onSave(
            payload.title,
            payload.description,
            payload.durationMinutes,
            payload.hourlyRateAmount,
            payload.currency,
            payload.iconSlug
        )
    }

    private func editorField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Brand.onSurfaceVariant)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .autocapitalization(.words)
                .disableAutocorrection(true)
                .font(.system(size: 15))
                .foregroundColor(Brand.onSurface)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Brand.surfaceContainerLow)
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Brand.outlineVariant.opacity(0.6), lineWidth: 1))
                )
        }
    }
}

// MARK: - Previews

#Preview("Add Topic") {
    TopicEditorView(topic: nil, onSave: { _, _, _, _, _, _ in }, onDismiss: {})
        .preferredColorScheme(.dark)
}

#Preview("Edit Topic") {
    TopicEditorView(
        topic: ExpertTopicItem(
            id: UUID(),
            title: "Go-to-Market Execution",
            durationMins: 60,
            description: "Positioning, GTM motions, ICP.",
            price: .init(amount: 25000, currency: "USD", isFree: false, label: "$250 / hr"),
            hourlyRate: .init(amount: 25000, currency: "USD"),
            iconSlug: "business"
        ),
        onSave: { _, _, _, _, _, _ in },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
