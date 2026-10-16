//
//  TopicEditorView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full-screen editor for adding or editing an expert topic. The parent
/// screen (`TopicsSetupView`) presents this via `.fullScreenCover` and
/// performs the real POST/PATCH after `onSave` fires.
struct TopicEditorView: View {

    @StateObject private var viewModel: TopicEditorViewModel

    /// Fires once the user taps Save and inputs pass local validation.
    /// Args: (title, description, durationMins, hourlyRateAmountMinorUnits,
    /// currency, iconSlug?, expertiseTagIds).
    ///
    /// Returns `nil` when the save succeeded, or a human-readable error
    /// message when it failed. The editor stays open on failure and
    /// surfaces the message in its own alert — so the user can correct
    /// and retry without the cover being torn down under them.
    let onSave: (String, String?, Int, Int, String, String?, [String]) async -> String?
    let onDismiss: () -> Void

    /// Error message from the most recent save attempt. Owned locally
    /// (not on the shared `TopicsSetupViewModel`) because SwiftUI's
    /// `.alert` bound to state on the presenter behaves erratically when
    /// attached to content inside a `fullScreenCover` — the alert would
    /// only render after the cover had dismissed. Owning the state here
    /// makes the alert reliably fire ON the editor.
    @State private var saveError: String?
    /// True while an async `onSave` is in flight. Blocks the Save button
    /// from being tapped twice.
    @State private var isSaving: Bool = false
    /// Presents `ExpertiseEditorSheet` inline so the expert can add
    /// profile-level expertise tags without having to bounce out to
    /// Settings first. The sheet writes through to `UserManager` on
    /// save; we mirror the fresh list back into the editor via
    /// `viewModel.applyProfileTagsUpdate`.
    @State private var showExpertiseEditor: Bool = false

    // MARK: Init

    /// Runtime init — seeds the editor from an existing topic (edit mode)
    /// or nil (add mode).
    init(
        topic: ExpertTopicItem?,
        onSave: @escaping (String, String?, Int, Int, String, String?, [String]) async -> String?,
        onDismiss: @escaping () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: TopicEditorViewModel(topic: topic))
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    /// Preview / test seam — inject a pre-configured view model.
    init(
        viewModel: TopicEditorViewModel,
        onSave: @escaping (String, String?, Int, Int, String, String?, [String]) async -> String? = { _, _, _, _, _, _, _ in nil },
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

                        durationStepper

                        VStack(alignment: .leading, spacing: 6) {
                            editorField(
                                label: "Price per Session ($)",
                                placeholder: "e.g. 150",
                                text: $viewModel.rate,
                                keyboard: .numberPad
                            )
                            if let hint = viewModel.minPriceHint {
                                Text(hint)
                                    .font(.caption.weight(.regular))
                                    .foregroundColor(viewModel.isRateBelowMinimum ? Brand.error : Brand.overlayWhite60)
                            }
                        }

                        tagPicker

                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(.caption.weight(.medium))
                                .foregroundColor(Brand.error)
                                .transition(.opacity)
                        }
                    }
                    .padding(24)
                }
            }
            .task { await viewModel.loadTags() }
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
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Brand.primary)
                        .disabled(isSaving)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
            // Alert lives on the editor's own state, not on the parent
            // view model — SwiftUI's `.alert` bound to state outside the
            // cover only rendered after the cover dismissed, which was
            // the whole reported bug ("error shows up after the view
            // has been popped"). Keeping it local makes the alert reliably
            // fire ON the editor so the user can correct + retry.
            .alert(
                "Couldn't save topic",
                isPresented: Binding(
                    get: { saveError != nil },
                    set: { if !$0 { saveError = nil } }
                ),
                presenting: saveError
            ) { _ in
                Button("OK", role: .cancel) {}
            } message: { message in
                Text(message)
            }
            // `.fullScreenCover` presents in a separate context so the
            // app-root keyboard toolbar doesn't reach the title / rate
            // TextFields — especially the number-pad rate field, which
            // has no Return key.
            .keyboardDismissToolbar()
            // Profile-tag editor — same sheet used from Settings, so
            // adds saved here appear everywhere expertise tags render.
            // The `onSaved` closure hands the fresh selection back so
            // the topic editor's tag picker updates in place, no
            // reload needed.
            .sheet(isPresented: $showExpertiseEditor) {
                ExpertiseEditorSheet { tags in
                    viewModel.applyProfileTagsUpdate(tags)
                }
            }
        }
    }

    // MARK: - Icon picker

    private var iconPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Icon")
                .font(.caption.weight(.semibold))
                .foregroundColor(Brand.onSurfaceVariant)

            // ScrollViewReader lets us jump the horizontal strip to
            // whichever chip is pre-selected on entry (edit mode) so
            // the user sees the highlighted icon without having to
            // scroll to find it. `.id(slug)` on the chip is what
            // `proxy.scrollTo` targets.
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.pickableSlugs, id: \.self) { slug in
                            iconChip(slug: slug)
                                .id(slug)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .onAppear {
                    // Only in edit mode — add mode has no selection to
                    // scroll to, so leave the strip anchored at the
                    // start (Ai, Business, …) as it renders today.
                    guard let selected = viewModel.iconSlug, !selected.isEmpty else { return }
                    // One-run delay so the ScrollView has finished its
                    // initial layout pass; scrolling before that lands
                    // at the wrong offset (SwiftUI quirk).
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(selected, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func iconChip(slug: String) -> some View {
        let selected = viewModel.isSelectedIcon(slug)
        return Button {
            viewModel.toggleIcon(slug)
        } label: {
            Image(systemName: CategoryIconMap.sfSymbol(forSlug: slug))
                .font(.body.weight(.semibold))
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

    // MARK: - Tag picker

    private var tagPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Expertise Tags")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Brand.onSurfaceVariant)
                Spacer()
                Text("Select up to \(viewModel.maxTagSelection)")
                    .font(.caption2.weight(.medium))
                    .foregroundColor(Brand.onSurfaceVariant)
                addExpertiseButton
            }

            if viewModel.isLoadingTags {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small).tint(Brand.onSurfaceVariant)
                    Text("Loading tags…")
                        .font(.caption)
                        .foregroundColor(Brand.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            } else if viewModel.availableTags.isEmpty {
                emptyExpertiseState
            } else {
                tagFilterField
                if viewModel.filteredTags.isEmpty {
                    Text("No tags match \"\(viewModel.tagFilter)\"")
                        .font(.caption)
                        .foregroundColor(Brand.onSurfaceVariant)
                        .padding(.top, 4)
                } else {
                    TopicsSetupFlowLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                        ForEach(viewModel.filteredTags) { tag in
                            tagPill(for: tag)
                        }
                    }
                }
            }
        }
    }

    /// Compact affordance in the section header. Always visible so a
    /// user with tags can still add more without leaving the editor.
    private var addExpertiseButton: some View {
        Button {
            showExpertiseEditor = true
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "plus")
                    .font(.caption2.weight(.bold))
                Text("Add")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(Brand.primary)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add expertise")
    }

    /// Shown when the expert has no profile expertise tags yet. Prompts
    /// them to add some without having to navigate to Settings first —
    /// same underlying `ExpertiseEditorSheet` as the header "+ Add" affordance.
    private var emptyExpertiseState: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("You don't have any expertise tags on your profile yet.")
                .font(.caption)
                .foregroundColor(Brand.onSurfaceVariant)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showExpertiseEditor = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                    Text("Add Expertise")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(Brand.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    Capsule().stroke(Brand.primary, lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    private var tagFilterField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.caption)
                .foregroundColor(Brand.onSurfaceVariant)
            TextField("Filter tags", text: $viewModel.tagFilter)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.subheadline)
                .foregroundColor(Brand.onSurface)
            if !viewModel.tagFilter.isEmpty {
                Button {
                    viewModel.tagFilter = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(Brand.onSurfaceVariant)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Brand.surfaceContainer)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Brand.outlineVariant.opacity(0.6), lineWidth: 1)
                )
        )
    }

    private func tagPill(for tag: ExpertiseTagItem) -> some View {
        let isSelected = viewModel.isSelectedTag(tag)
        let atCap = viewModel.selectedTagIds.count >= viewModel.maxTagSelection && !isSelected

        return Button {
            viewModel.toggleTag(tag)
        } label: {
            Text(tag.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(isSelected ? Brand.primary : Brand.onSurfaceVariant)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Brand.primary.opacity(0.08) : Color.clear)
                        .overlay(
                            Capsule().stroke(
                                isSelected ? Brand.primary : Brand.outlineVariant,
                                lineWidth: isSelected ? 1.2 : 1
                            )
                        )
                )
        }
        .buttonStyle(.plain)
        .disabled(atCap)
        .opacity(atCap ? 0.45 : 1)
    }

    // MARK: - Duration stepper

    private var durationStepper: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Session Duration")
                .font(.caption.weight(.semibold))
                .foregroundColor(Brand.onSurfaceVariant)

            Stepper(
                value: $viewModel.durationMinutes,
                in: viewModel.durationRange,
                step: viewModel.durationStep
            ) {
                Text(formatDuration(viewModel.durationMinutes))
                    .font(.subheadline)
                    .foregroundColor(Brand.onSurface)
            }
            .tint(Brand.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Brand.surfaceContainerLow)
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Brand.outlineVariant.opacity(0.6), lineWidth: 1))
            )
        }
    }

    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours == 0 { return "\(mins) min" }
        if mins == 0 { return hours == 1 ? "1 hour" : "\(hours) hours" }
        return "\(hours) hr \(mins) min"
    }

    // MARK: - Save

    /// Validates locally, then hands the payload to `onSave`. On success
    /// (`nil` return), fires `onDismiss()` so the parent can close the
    /// cover. On failure, stashes the message in `saveError` — the
    /// `.alert` bound to it fires ON this view, keeping the editor open
    /// and giving the user a chance to correct and retry.
    private func attemptSave() {
        guard !isSaving, let payload = viewModel.validate() else { return }
        isSaving = true
        Task {
            let error = await onSave(
                payload.title,
                payload.description,
                payload.durationMinutes,
                payload.hourlyRateAmount,
                payload.currency,
                payload.iconSlug,
                payload.expertiseTagIds
            )
            isSaving = false
            if let error {
                saveError = error
            } else {
                onDismiss()
            }
        }
    }

    private func editorField(label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(Brand.onSurfaceVariant)

            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.sentences)
                .disableAutocorrection(true)
                .font(.subheadline)
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
    TopicEditorView(topic: nil, onSave: { _, _, _, _, _, _, _ in nil }, onDismiss: {})
        .preferredColorScheme(.dark)
}

#Preview("Edit Topic") {
    TopicEditorView(
        topic: ExpertTopicItem(
            id: UUID(),
            title: "Go-to-Market Execution",
            durationMins: 60,
            description: "Positioning, GTM motions, ICP.",
            price: .init(amount: 25000, currency: "USD", isFree: false, label: "$250"),
            hourlyRate: .init(amount: 25000, currency: "USD"),
            iconSlug: "business",
            expertiseTags: nil
        ),
        onSave: { _, _, _, _, _, _, _ in nil },
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
