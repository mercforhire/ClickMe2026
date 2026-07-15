//
//  RequestDecisionView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

enum SessionType {
    case virtual, onsite

    var label: String {
        self == .virtual ? "Virtual Meeting" : "On-site Hub"
    }

    var icon: String {
        self == .virtual ? "video" : "mappin"
    }
}

struct IncomingRequest: Identifiable {
    let id = UUID()
    let clientName: String
    let topic: String
    let date: String
    let time: String
    let duration: String // e.g. "60m"
    let earnings: Double
    let sessionType: SessionType
    let imageURL: String
    let isHighPriority: Bool
    let isReturning: Bool
    let clientNote: String? // optional preview message
    let isOnline: Bool

    var timeRange: String {
        "\(time) (\(duration))"
    }

    var isVirtual: Bool {
        sessionType == .virtual
    }
}

// MARK: - Sample data

extension IncomingRequest {
    static let samples: [IncomingRequest] = [
        IncomingRequest(
            clientName: "Elena Rodriguez",
            topic: "Marketing Strategy Review",
            date: "Oct 24, 2023",
            time: "02:30 PM",
            duration: "60m",
            earnings: 180.00,
            sessionType: .virtual,
            imageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            isHighPriority: false,
            isReturning: false,
            clientNote: nil,
            isOnline: true
        ),
        IncomingRequest(
            clientName: "Dr. Simon K.",
            topic: "Executive Leadership",
            date: "Oct 26, 2023",
            time: "11:00 AM",
            duration: "90m",
            earnings: 275.00,
            sessionType: .onsite,
            imageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            isHighPriority: false,
            isReturning: false,
            clientNote: nil,
            isOnline: false
        ),
        IncomingRequest(
            clientName: "Sarah Jenkins",
            topic: "Q4 Strategy Deep Dive",
            date: "Oct 27, 2023",
            time: "10:00 AM",
            duration: "60m",
            earnings: 210.00,
            sessionType: .virtual,
            imageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            isHighPriority: true,
            isReturning: true,
            clientNote: "Hi! Looking to dive deeper into the Q4 results we discussed last time...",
            isOnline: true
        ),
    ]
}

// MARK: - Booking Request Detail View

struct RequestDecisionView: View {
    @State var viewModel: RequestDecisionViewModel

    // MARK: Init

    init(viewModel: RequestDecisionViewModel = RequestDecisionViewModel()) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: Body

    var body: some View {
        ZStack {
            RequestDecisionTheme.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        RequestDecisionClientHeader(request: viewModel.request) {
                            viewModel.viewProfileTapped()
                        }
                        RequestDecisionDetailsCard(request: viewModel.request)
                        RequestDecisionMessageSection(clientMessage: viewModel.clientMessage)
                        RequestDecisionEarningsSection(potentialEarnings: viewModel.potentialEarnings)
                    }
                    .padding(16)
                    .padding(.bottom, 8)
                }

                Divider().background(RequestDecisionTheme.divider)

                RequestDecisionActionFooter(
                    isAccepted: viewModel.isAccepted,
                    isDeclined: viewModel.isDeclined,
                    onMessage: viewModel.messageTapped,
                    onDeclineTap: viewModel.openDeclineSheet,
                    onAcceptTap: viewModel.openAcceptSheet
                )
            }

            // ── Bottom-sheet overlays ──
            if viewModel.showAcceptSheet {
                sheetOverlay {
                    RequestDecisionAcceptSheet(
                        request: viewModel.request,
                        onCancel: viewModel.dismissSheets,
                        onConfirm: { _ in viewModel.confirmAccept() }
                    )
                }
            }

            if viewModel.showDeclineSheet {
                sheetOverlay {
                    RequestDecisionDeclineSheet(
                        request: viewModel.request,
                        onCancel: viewModel.dismissSheets,
                        onDecline: { _ in viewModel.confirmDecline() }
                    )
                }
            }
        }
        .navigationTitle("Booking Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Sheet overlay wrapper (consistent positioning)

    private func sheetOverlay<Sheet: View>(@ViewBuilder sheet: () -> Sheet) -> some View {
        ZStack(alignment: .bottom) {
            // Scrim
            Color.black.opacity(0.60)
                .ignoresSafeArea()
                .onTapGesture { viewModel.dismissSheets() }

            // Sheet slides up from the bottom
            sheet()
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.showAcceptSheet)
        .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.showDeclineSheet)
    }
}

// MARK: - Previews

private struct RequestDecisionPreviewHost: View {
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            Color.clear
                .navigationDestination(for: Int.self) { _ in
                    RequestDecisionView()
                }
        }
    }
}

#Preview("Default") {
    RequestDecisionPreviewHost()
        .preferredColorScheme(.dark)
}

#Preview("Accept Sheet open") {
    AcceptSheetPreview()
        .preferredColorScheme(.dark)
}

#Preview("Decline Sheet open") {
    DeclineSheetPreview()
        .preferredColorScheme(.dark)
}

/// Preview wrappers to show sheets immediately
private struct AcceptSheetPreview: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RequestDecisionTheme.bg.ignoresSafeArea()
            RequestDecisionAcceptSheet(
                request: IncomingRequest.samples[0],
                onCancel: {},
                onConfirm: { _ in }
            )
        }
    }
}

private struct DeclineSheetPreview: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RequestDecisionTheme.bg.ignoresSafeArea()
            RequestDecisionDeclineSheet(
                request: IncomingRequest.samples[0],
                onCancel: {},
                onDecline: { _ in }
            )
        }
    }
}
