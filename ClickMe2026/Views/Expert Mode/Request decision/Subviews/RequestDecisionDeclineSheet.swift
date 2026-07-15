//
//  RequestDecisionDeclineSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionDeclineSheet: View {
    let request: IncomingRequest
    let onCancel: () -> Void
    let onDecline: (String) -> Void

    @State private var reason = ""
    @State private var showReasonError = false

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: 48, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 20)

            VStack(spacing: 24) {
                // Title + subtitle
                VStack(spacing: 8) {
                    Text("Decline Booking Request?")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(RequestDecisionTheme.onSurface)
                        .multilineTextAlignment(.center)

                    Text("Are you sure you want to decline this booking request? This action cannot be undone.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(RequestDecisionTheme.onSurfaceVar)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }

                // Summary card
                VStack(spacing: 0) {
                    summaryRow(label: "From", value: request.clientName)
                    Divider().background(RequestDecisionTheme.divider)
                    summaryRow(label: "Date & Time", value: "\(request.date), \(request.timeRange)")
                    Divider().background(RequestDecisionTheme.divider)
                    summaryRow(label: "Topic", value: request.topic)
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(RequestDecisionTheme.sheetInnerBg))

                // Reason field (required)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Text("Reason for declining")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(RequestDecisionTheme.onSurface)
                        Text("*")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(RequestDecisionTheme.destructive)
                    }

                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(RequestDecisionTheme.sheetInnerBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(showReasonError
                                        ? RequestDecisionTheme.destructive.opacity(0.70)
                                        : Color.white.opacity(0.15),
                                        lineWidth: 1)
                            )
                            .frame(minHeight: 88)

                        if reason.isEmpty {
                            Text("e.g. Unavailable, Not in my expertise")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(Color.white.opacity(0.35))
                                .padding(.horizontal, 12)
                                .padding(.top, 12)
                        }

                        TextEditor(text: $reason)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundColor(RequestDecisionTheme.onSurface)
                            .font(.system(size: 13, design: .rounded))
                            .frame(minHeight: 88)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .onChange(of: reason) {
                                if showReasonError && !reason.isEmpty { showReasonError = false }
                            }
                    }

                    if showReasonError {
                        Text("Please provide a reason before declining.")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(RequestDecisionTheme.destructive)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: showReasonError)

                // Buttons
                HStack(spacing: 12) {
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(RequestDecisionTheme.onSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.22)))
                    }
                    .buttonStyle(RequestDecisionActionStyle())

                    Button {
                        guard !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                            withAnimation { showReasonError = true }
                            return
                        }
                        onDecline(reason)
                    } label: {
                        Text("Decline")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(RequestDecisionTheme.destructive)
                                .shadow(color: RequestDecisionTheme.destructive.opacity(0.35), radius: 6, x: 0, y: 2))
                    }
                    .buttonStyle(RequestDecisionActionStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 36)
        }
        .background(
            RequestDecisionTheme.sheetBg
                .clipShape(RequestDecisionRoundedCorner(radius: 24, corners: [.topLeft, .topRight]))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func summaryRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurfaceVar)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurface)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}
