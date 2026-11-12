//
//  ExpertProfileStateView.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

/// Full-screen state shown instead of the profile when `GET /experts/:id/details`
/// returns 404 (`notFound`, Back only) or fails for any other reason
/// (`failed`, Retry). Replaces the scroll content; the system back chevron
/// stays in the nav bar.
struct ExpertProfileStateView: View {

    enum Kind: Equatable {
        case notFound
        case failed(message: String)
    }

    let kind: Kind

    /// True while a Retry is running: the capsule is replaced by a spinner.
    var isWorking: Bool = false

    /// Back (pops one level) for `notFound`, Retry for `failed`.
    let onAction: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: iconName)
                .font(.title.weight(.regular))
                .foregroundColor(Brand.onSurfaceVariant)

            VStack(spacing: 4) {
                Text(heading)
                    .font(.brand(.callout, weight: .semibold))
                    .foregroundColor(Brand.onSurface)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.brand(.subheadline))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if isWorking {
                ProgressView()
                    .tint(Brand.primary)
                    .frame(height: 48)
            } else {
                Button(action: onAction) {
                    Text(buttonTitle)
                        .font(.brand(.callout, weight: .semibold))
                        .foregroundColor(Brand.onPrimary)
                        .padding(.horizontal, 32)
                        .frame(height: 48)
                        .background(Capsule().fill(Brand.primary))
                }
                .buttonStyle(PressScaleButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Copy

    private var iconName: String {
        switch kind {
        case .notFound: "person.crop.circle.badge.xmark"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var heading: String {
        switch kind {
        case .notFound: "This profile isn't available"
        case .failed: "Couldn't load profile"
        }
    }

    private var message: String {
        switch kind {
        case .notFound: "This expert may no longer be on ClickMe. Go back and try someone else."
        case .failed(let message): message
        }
    }

    private var buttonTitle: String {
        switch kind {
        case .notFound: "Back"
        case .failed: "Retry"
        }
    }
}

// MARK: - Previews

#Preview("Not available") {
    ZStack {
        ExpertProfileBrand.bg.ignoresSafeArea()
        ExpertProfileStateView(kind: .notFound, onAction: {})
    }
}

#Preview("Load failed") {
    ZStack {
        ExpertProfileBrand.bg.ignoresSafeArea()
        ExpertProfileStateView(
            kind: .failed(message: "The Internet connection appears to be offline."),
            onAction: {}
        )
    }
}
