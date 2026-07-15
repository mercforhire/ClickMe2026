//
//  MeetingCallEndButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Full-width red "End Call" button

struct MeetingCallEndButton: View {
    let isEnding: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text("End Call")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                MeetingCallBrand.endRed,
                                MeetingCallBrand.endRedDeep,
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: MeetingCallBrand.endRed.opacity(0.45), radius: 14, x: 0, y: 5)
            )
        }
        .buttonStyle(CallControlStyle())
        .disabled(isEnding)
        .opacity(isEnding ? 0.60 : 1.0)
    }
}
