//
//  ChattingInputBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Bottom input bar

struct ChattingInputBar: View {
    let myAvatarURL: String
    @Binding var text: String
    @Binding var selectedPhoto: PhotosPickerItem?
    @FocusState.Binding var inputFocused: Bool
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ChattingAvatar(url: myAvatarURL, size: 32)

            HStack(alignment: .bottom, spacing: 8) {
                TextField("Message", text: $text, axis: .vertical)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(ChattingBrand.onSurface)
                    .tint(ChattingBrand.brandGreen)
                    .lineLimit(1 ... 5)
                    .focused($inputFocused)

                Spacer(minLength: 0)

                Button {} label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(ChattingBrand.onSurfaceVar)
                }

                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(ChattingBrand.brandGreen)
                    }
                    .transition(.scale.combined(with: .opacity))
                } else {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: "photo")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(ChattingBrand.onSurfaceVar)
                    }
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
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ChattingBrand.navBg
                .overlay(alignment: .top) {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                }
        )
    }
}
