//
//  RequestDecisionAcceptSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionAcceptSheet: View {
    let request: IncomingRequest
    let onCancel: () -> Void
    let onConfirm: (String) -> Void

    @State private var message = ""

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.white.opacity(0.20))
                .frame(width: 48, height: 6)
                .padding(.top, 12)
                .padding(.bottom, 12)

            // Content scrolls if it overflows so the buttons at the bottom
            // can't be clipped on smaller devices or when the keyboard is
            // up over the TextEditor.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Title
                    Text("Confirm Booking")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Brand.onSurface)

                    // Summary card
                    VStack(spacing: 0) {
                        summaryRow(label: "With:", value: request.clientName)
                        Divider().background(Brand.overlayWhite10)
                        summaryRow(label: "When:", value: "\(request.date), \(request.timeRange)")
                        Divider().background(Brand.overlayWhite10)
                        summaryRow(label: "Topic:", value: request.topic)
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(RequestDecisionTheme.sheetInnerBg))

                    // Optional message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a message (optional)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(Brand.onSurface)

                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(RequestDecisionTheme.sheetInnerBg)
                                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1))
                                .frame(minHeight: 72)

                            if message.isEmpty {
                                Text("e.g., Looking forward to our session!")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.35))
                                    .padding(.horizontal, 12)
                                    .padding(.top, 12)
                            }

                            TextEditor(text: $message)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .foregroundColor(Brand.onSurface)
                                .font(.system(size: 13, design: .rounded))
                                .frame(minHeight: 72)
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

                        Button { onConfirm(message) } label: {
                            Text("Confirm")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(Brand.onPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Brand.primary)
                                    .shadow(color: Brand.primary.opacity(0.35), radius: 6, x: 0, y: 2))
                        }
                        .buttonStyle(PressScaleButtonStyle())
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        // Cap the sheet at ~65% of the screen so it doesn't cover the nav
        // bar / status bar; the inner ScrollView handles overflow.
        .frame(maxHeight: UIScreen.main.bounds.height * 0.65)
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
