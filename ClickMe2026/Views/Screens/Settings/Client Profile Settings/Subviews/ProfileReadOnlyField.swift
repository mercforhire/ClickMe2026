//
//  ProfileReadOnlyField.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Read-only rounded labeled value row

/// Visual twin of `ProfileLabeledField`, but the value is a
/// non-editable `Text`. Used for fields the user isn't allowed to edit
/// from the settings screen (email today; add more later as needed).
///
/// Two copy affordances layered on the same row so users of different
/// skill levels can discover it:
/// - Trailing `doc.on.doc` icon → one-tap copy, with a brief green
///   checkmark confirmation.
/// - `.textSelection(.enabled)` + `.contextMenu { Copy }` → native
///   long-press select/copy behavior, matches system expectations.
///
/// The full value is always shown — no truncation — so long emails
/// wrap onto a second line rather than being clipped.
struct ProfileReadOnlyField: View {
    let label: String
    let value: String

    @State private var justCopied: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.brand(.caption2, weight: .semibold))
                        .foregroundColor(ProfileSettingsBrand.labelColor)
                    Text(value)
                        .font(.brand(.subheadline))
                        .foregroundColor(ProfileSettingsBrand.onSurface)
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                        .contextMenu {
                            Button {
                                copy()
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                            }
                        }
                }

                Spacer(minLength: 0)

                Button {
                    copy()
                } label: {
                    Image(systemName: justCopied ? "checkmark" : "doc.on.doc")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(justCopied ? ProfileSettingsBrand.brandGreen : ProfileSettingsBrand.labelColor)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(justCopied ? "Copied" : "Copy \(label)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 60)
    }

    // MARK: - Copy

    /// Puts the value on the pasteboard, flips the icon to a checkmark
    /// for ~1.5s, and fires a light haptic so the tap is felt as well
    /// as seen.
    private func copy() {
        UIPasteboard.general.string = value
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeInOut(duration: 0.15)) {
            justCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                justCopied = false
            }
        }
    }
}
