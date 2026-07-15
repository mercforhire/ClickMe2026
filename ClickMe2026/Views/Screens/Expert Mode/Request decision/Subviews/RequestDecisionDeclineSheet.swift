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
    /// Fires with `(reasonCode, reasonText)` — codes match the server's
    /// enum (`UNAVAILABLE`, `OUTSIDE_EXPERTISE`, etc.). Text is free-form
    /// and shown to the client verbatim.
    let onDecline: (String, String) -> Void

    @State private var selectedReason: DeclineReason = .unavailable
    @State private var reasonText = ""

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: 48, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 12)

            // Content scrolls if it overflows so nothing (especially the
            // bottom buttons) can be clipped when the picker + optional
            // note push the sheet past the screen height.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Title + subtitle
                    VStack(spacing: 6) {
                        Text("Decline Booking Request?")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Brand.onSurface)
                            .multilineTextAlignment(.center)

                        Text("This action cannot be undone.")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundColor(Brand.overlayWhite60)
                            .multilineTextAlignment(.center)
                    }

                    // Summary card
                    VStack(spacing: 0) {
                        summaryRow(label: "From", value: request.clientName)
                        Divider().background(Brand.overlayWhite10)
                        summaryRow(label: "Date & Time", value: "\(request.date), \(request.timeRange)")
                        Divider().background(Brand.overlayWhite10)
                        summaryRow(label: "Topic", value: request.topic)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RequestDecisionTheme.sheetInnerBg))

                    // Reason code picker (server enum)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Reason for declining")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundColor(Brand.onSurface)
                            Text("*")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Brand.destructive)
                        }

                        Menu {
                            ForEach(DeclineReason.allCases) { reason in
                                Button(reason.label) { selectedReason = reason }
                            }
                        } label: {
                            HStack {
                                Text(selectedReason.label)
                                    .foregroundColor(Brand.onSurface)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Brand.overlayWhite60)
                            }
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(RequestDecisionTheme.sheetInnerBg)
                                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1))
                            )
                        }
                    }

                    // Optional free text
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Optional note to the client")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Brand.onSurface)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(RequestDecisionTheme.sheetInnerBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                                .frame(minHeight: 64)

                            if reasonText.isEmpty {
                                Text("e.g. Sorry — booked solid that week.")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.35))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)
                            }

                            TextEditor(text: $reasonText)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(Brand.onSurface)
                                .font(.system(size: 13, design: .rounded))
                                .frame(minHeight: 64)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                        }
                    }

                    // Buttons
                    HStack(spacing: 12) {
                        Button(action: onCancel) {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Brand.onSurface)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.22)))
                        }
                        .buttonStyle(PressScaleButtonStyle())

                        Button {
                            onDecline(selectedReason.rawValue, reasonText)
                        } label: {
                            Text("Decline")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Brand.destructive)
                                    .shadow(color: Brand.destructive.opacity(0.35), radius: 6, x: 0, y: 2))
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        // Cap the sheet at ~75% of the screen so it doesn't cover the
        // nav bar / status bar; the inner ScrollView handles overflow.
        .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
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
                .foregroundColor(Brand.overlayWhite60)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Brand.onSurface)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
    }
}
