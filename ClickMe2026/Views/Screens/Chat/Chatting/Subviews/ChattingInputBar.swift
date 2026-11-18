//
//  ChattingInputBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - Bottom input bar

struct ChattingInputBar: View {
    let myAvatarURL: String
    @Binding var text: String
    @FocusState.Binding var inputFocused: Bool
    let onSend: () -> Void

    private var length: Int { text.utf16.count }

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            composerRow
            counter
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .onChange(of: text) { old, new in
            if ChatComposerRules.crossedLimit(oldLength: old.utf16.count, newLength: new.utf16.count) {
                AccessibilityNotification.Announcement("Message length limit reached").post()
            }
        }
        .background(
            ChattingBrand.navBg
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
        )
    }

    // MARK: Composer row

    private var composerRow: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ChattingAvatar(url: myAvatarURL, size: 32)

            // The field stays enabled and focused while sends are in flight (D-01).
            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $text, axis: .vertical)
                    .font(.brand(.subheadline))
                    .foregroundColor(ChattingBrand.onSurface)
                    .tint(ChattingBrand.brandGreen)
                    .lineLimit(1 ... 5)
                    .focused($inputFocused)

                Spacer(minLength: 0)

                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.callout.weight(.regular))
                            .foregroundColor(ChattingBrand.brandGreen)
                    }
                    .accessibilityLabel("Send message")
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(ChattingBrand.inputBg)
                    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(ChattingBrand.inputBorder, lineWidth: 1))
            )
            .animation(.easeInOut(duration: 0.18), value: text.isEmpty)
        }
    }

    // MARK: Counter (D-04)

    /// `{n} / 10,000` from 9,000 units, red at the cap. Reserves no space below 9,000.
    /// Hidden from VoiceOver until the cap, where it reads `{n} of 10,000 characters`.
    @ViewBuilder
    private var counter: some View {
        if ChatComposerRules.showsCounter(length: length) {
            let atLimit = ChatComposerRules.isAtLimit(length: length)
            Text(ChatComposerRules.counterText(length: length))
                .font(.brand(.caption))
                .foregroundColor(atLimit ? Brand.error : ChattingBrand.onSurfaceVar)
                .padding(.trailing, 16)
                .accessibilityHidden(!atLimit)
                .accessibilityLabel(ChatComposerRules.accessibilityCounterLabel(length: length))
        }
    }
}
