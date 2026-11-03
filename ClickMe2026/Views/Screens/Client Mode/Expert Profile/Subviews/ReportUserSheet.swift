//
//  ReportUserSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Lightweight profile-report sheet backed by `POST /users/:id/report`.
/// Thread-independent (unlike `ReportChatView` which requires a chat
/// thread), so it can be launched from any surface where one user
/// encounters another. Pattern per `docs/ios/USER-REPORTING.md` §1.
struct ReportUserSheet: View {

    let userId: UUID
    let userName: String
    var onSubmitted: () -> Void
    var onDismiss: () -> Void

    @State private var selectedReason: UserReportReason?
    @State private var details: String = ""
    @State private var isSubmitting: Bool = false
    @State private var submissionError: String?
    @State private var didSubmit: Bool = false

    private let api: ClickMeAPI = .shared

    private let maxDetailsLength = 1000

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(UserReportReason.allCases) { reason in
                        Button {
                            selectedReason = reason
                        } label: {
                            HStack {
                                Text(reason.displayLabel)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Why are you reporting \(userName)?")
                }

                Section {
                    TextField("Add any additional context (optional)",
                              text: $details, axis: .vertical)
                        .lineLimit(3 ... 8)
                        .onChange(of: details) { _, newValue in
                            if newValue.count > maxDetailsLength {
                                details = String(newValue.prefix(maxDetailsLength))
                            }
                        }
                } header: {
                    Text("Details")
                } footer: {
                    Text("\(details.count)/\(maxDetailsLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let message = submissionError {
                    Section {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(didSubmit ? "Sent" : "Submit") {
                        Task { await submit() }
                    }
                    .disabled(selectedReason == nil || isSubmitting || didSubmit)
                }
            }
        }
    }

    private func submit() async {
        guard let reason = selectedReason, !isSubmitting else { return }
        isSubmitting = true
        submissionError = nil
        defer { isSubmitting = false }

        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            _ = try await api.reportUser(
                id: userId,
                reason: reason,
                details: trimmed.isEmpty ? nil : trimmed
            )
            didSubmit = true
            onSubmitted()
        } catch {
            submissionError = error.userMessage
        }
    }
}
