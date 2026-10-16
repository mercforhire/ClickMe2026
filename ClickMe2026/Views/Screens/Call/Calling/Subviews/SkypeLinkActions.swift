//
//  SkypeLinkActions.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// The two link-related actions on the Skype/Zoom variant of the call
/// screen: "Open in Skype/Zoom" (primary, filled brand-green) and
/// "Copy Link" (secondary, outlined). Below them, a transient "Link
/// copied" chip fades in and out on copy.
struct SkypeLinkActions: View {
    /// Nil while `POST /join` is still in flight or when the server
    /// omitted `external_config.join_url`. Both buttons disable in
    /// that case rather than firing a no-op.
    let joinURL: URL?
    let showCopiedToast: Bool
    var onOpen: () -> Void
    var onCopy: () -> Void

    /// Provider inferred from the URL — drives the button label + icon
    /// so a Zoom link doesn't read "Open in Skype" and vice versa. The
    /// backend groups all external meetings under one `skype_zoom`
    /// bucket, so URL sniffing is the client's only signal.
    private var provider: ExternalMeetingProvider {
        ExternalMeetingProvider.detect(from: joinURL)
    }

    var body: some View {
        VStack(spacing: 12) {
            openButton
            copyButton

            if showCopiedToast {
                Text("Link copied")
                    .font(.brand(.caption, weight: .semibold))
                    .foregroundColor(MeetingCallBrand.onSurface)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(MeetingCallBrand.surfaceHigh)
                            .overlay(Capsule().stroke(MeetingCallBrand.brandGreen.opacity(0.60), lineWidth: 1))
                    )
                    .transition(.opacity)
            }
        }
    }

    private var openButton: some View {
        Button(action: onOpen) {
            HStack(spacing: 10) {
                Image(systemName: provider.iconSystemName)
                    .font(.callout.weight(.semibold))
                Text("Open in \(provider.displayName)")
                    .font(.brand(.callout, weight: .bold))
            }
            .foregroundColor(MeetingCallBrand.bg)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MeetingCallBrand.brandGreen)
                    .shadow(color: MeetingCallBrand.brandGreen.opacity(0.45), radius: 14, x: 0, y: 4)
            )
        }
        .buttonStyle(CallControlStyle())
        .disabled(joinURL == nil)
        .opacity(joinURL == nil ? 0.55 : 1.0)
    }

    private var copyButton: some View {
        Button(action: onCopy) {
            HStack(spacing: 8) {
                Image(systemName: "doc.on.doc")
                    .font(.subheadline.weight(.semibold))
                Text("Copy Link")
                    .font(.brand(.subheadline, weight: .semibold))
            }
            .foregroundColor(MeetingCallBrand.onSurface)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(MeetingCallBrand.onSurface.opacity(0.20), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(joinURL == nil)
        .opacity(joinURL == nil ? 0.45 : 1.0)
    }
}
