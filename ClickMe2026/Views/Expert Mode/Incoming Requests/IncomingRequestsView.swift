//
//  IncomingRequests.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//
import SwiftUI

// MARK: - Models

struct BookingRequest: Identifiable {
    let id = UUID()
    let clientName: String
    let clientImageURL: String
    let topic: String
    let dateTime: String
    let earnings: String
    let expiresInHours: Int
    let isHighPriority: Bool // true = green neon ring, false = subtle grey ring
}

// MARK: - Incoming Requests View

struct IncomingRequestsView: View {
    let viewModel: IncomingRequestsViewModel

    init(viewModel: IncomingRequestsViewModel = IncomingRequestsViewModel()) {
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            IncomingRequestsTheme.bg.ignoresSafeArea()
            IncomingRequestsBlobLayer().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Incoming requests")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(IncomingRequestsTheme.onSurface)
                        .padding(.horizontal, 20)
                        .padding(.top, 56)

                    VStack(spacing: 16) {
                        ForEach(viewModel.requests) { request in
                            IncomingRequestCard(request: request, onTap: viewModel.onRequestTap)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

// MARK: - Sample data

extension BookingRequest {
    static let samples: [BookingRequest] = [
        BookingRequest(
            clientName: "Liam Carter",
            clientImageURL: "https://randomuser.me/api/portraits/men/55.jpg",
            topic: "Career Advice",
            dateTime: "Oct 15, 10:00 AM - 11:00 AM",
            earnings: "$75.00",
            expiresInHours: 14,
            isHighPriority: true
        ),
        BookingRequest(
            clientName: "Sarah Jones",
            clientImageURL: "https://randomuser.me/api/portraits/women/44.jpg",
            topic: "Design Review",
            dateTime: "Oct 16, 2:00 PM - 3:00 PM",
            earnings: "$120.00",
            expiresInHours: 1,
            isHighPriority: false
        ),
        BookingRequest(
            clientName: "Michael Chen",
            clientImageURL: "https://randomuser.me/api/portraits/men/32.jpg",
            topic: "Portfolio Feedback",
            dateTime: "Oct 17, 4:30 PM - 5:30 PM",
            earnings: "$90.00",
            expiresInHours: 23,
            isHighPriority: true
        ),
    ]
}

// MARK: - Preview

private struct IncomingRequestsPreviewHost: View {
    let destination: IncomingRequestsView
    @State private var path: [Int] = [0]

    var body: some View {
        NavigationStack(path: $path) {
            Color.clear
                .navigationDestination(for: Int.self) { _ in
                    destination
                }
        }
    }
}

#Preview("Incoming Requests") {
    IncomingRequestsPreviewHost(destination: IncomingRequestsView())
        .preferredColorScheme(.dark)
}
