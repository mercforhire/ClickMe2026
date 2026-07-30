//
//  MeetingCallPill.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Floating "call in progress" indicator shown by both shells at the
/// bottom-right of the screen when `CallCenter.isMinimized` is true.
/// Tap → expand back to the full call surface. Never ends the call —
/// only the red Hang Up button inside the expanded call does that.
struct MeetingCallPill: View {
    @ObservedObject var viewModel: MeetingCallViewModel
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                avatar
                Text(viewModel.timerString)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(MeetingCallBrand.onSurface)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(MeetingCallBrand.surfaceHigh)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(MeetingCallBrand.brandGreen.opacity(0.55), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Return to call")
    }

    private var avatar: some View {
        ZStack {
            AsyncImage(url: URL(string: viewModel.expertImageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        MeetingCallBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.25))
                    }
                }
            }
            .frame(width: 24, height: 24)
            .clipShape(Circle())
            .overlay(Circle().stroke(MeetingCallBrand.brandGreen, lineWidth: 1.5))
        }
    }
}
