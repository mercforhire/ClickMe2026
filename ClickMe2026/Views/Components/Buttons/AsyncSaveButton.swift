//
//  AsyncSaveButton.swift
//  ClickMe2026
//
//  Full-width capsule button with three visual states:
//  - idle: shows `title`
//  - saving: shows a spinner
//  - saved: shows a check + "Saved!" (or custom savedTitle)
//

import SwiftUI

enum SaveState {
    case idle
    case saving
    case saved
}

struct AsyncSaveButton: View {
    let title: String
    let state: SaveState
    var savedTitle: String = "Saved!"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Capsule()
                    .fill(Brand.primary)
                    .shadow(color: Brand.primary.opacity(0.50), radius: 18, x: 0, y: 5)
                    .frame(height: 56)

                switch state {
                case .saving:
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Brand.onPrimary))
                case .saved:
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.body.weight(.semibold))
                        Text(savedTitle)
                            .font(.brand(.body, weight: .bold))
                    }
                    .foregroundColor(Brand.onPrimary)
                case .idle:
                    Text(title)
                        .font(.brand(.body, weight: .bold))
                        .foregroundColor(Brand.onPrimary)
                }
            }
        }
        .frame(height: 56)
        .disabled(state != .idle)
        .buttonStyle(PressScaleButtonStyle())
    }
}
