//
//  ReadyToStartCallView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Connect via Skype View

struct ReadyToStartCallView: View {
    @StateObject private var viewModel: ReadyToStartCallViewModel

    var onJoinCall: () -> Void
    var onContactSupport: () -> Void
    var onMessageParticipant: () -> Void

    // MARK: Init

    init(
        viewModel: ReadyToStartCallViewModel = ReadyToStartCallViewModel(),
        onJoinCall: @escaping () -> Void = {},
        onContactSupport: @escaping () -> Void = {},
        onMessageParticipant: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onJoinCall = onJoinCall
        self.onContactSupport = onContactSupport
        self.onMessageParticipant = onMessageParticipant
    }

    /// Convenience init mirroring the prior signature so existing call sites
    /// that pass a Skype link keep compiling.
    init(
        skypeLink: String,
        onJoinCall: @escaping () -> Void = {},
        onContactSupport: @escaping () -> Void = {},
        onMessageParticipant: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: ReadyToStartCallViewModel(skypeLink: skypeLink),
            onJoinCall: onJoinCall,
            onContactSupport: onContactSupport,
            onMessageParticipant: onMessageParticipant
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ReadyToStartCallBrand.bg.ignoresSafeArea()
            ReadyToStartCallBlobLayer().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    ReadyToStartCallSkypeIcon(
                        scale: viewModel.iconScale,
                        opacity: viewModel.iconOpacity,
                        glowPulse: viewModel.glowPulse
                    )

                    ReadyToStartCallHeadline(
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset
                    )

                    ReadyToStartCallJoinButton(
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset,
                        action: onJoinCall
                    )

                    ReadyToStartCallLinkCard(
                        skypeLink: viewModel.skypeLink,
                        didCopy: viewModel.didCopy,
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset,
                        onCopy: { viewModel.copyLink() }
                    )

                    ReadyToStartCallSupportRow(
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset,
                        onContactSupport: onContactSupport
                    )

                    ReadyToStartCallMessageButton(
                        opacity: viewModel.bodyOpacity,
                        yOffset: viewModel.bodyOffset,
                        action: onMessageParticipant
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Connect via Skype")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(ReadyToStartCallBrand.bg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { viewModel.runEntryAnimation() }
    }
}

// MARK: - Preview harness

private enum ReadyToStartCallPreviewRoute: Hashable {
    case connect
}

/// Wraps the connect-via-Skype screen inside a NavigationStack with a
/// dummy "Upcoming session" parent already pushed, so the system back
/// chevron renders in the canvas.
private struct ReadyToStartCallPreviewHarness: View {
    let route: ReadyToStartCallPreviewRoute
    @State private var path: [ReadyToStartCallPreviewRoute]

    init(route: ReadyToStartCallPreviewRoute) {
        self.route = route
        _path = State(initialValue: [route])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Session details")
                NavigationLink("Ready to join", value: route)
            }
            .navigationTitle("Upcoming session")
            .navigationDestination(for: ReadyToStartCallPreviewRoute.self) { _ in
                ReadyToStartCallView()
            }
        }
    }
}

// MARK: - Previews

#Preview("Connect via Skype") {
    ReadyToStartCallPreviewHarness(route: .connect)
        .preferredColorScheme(.dark)
}
