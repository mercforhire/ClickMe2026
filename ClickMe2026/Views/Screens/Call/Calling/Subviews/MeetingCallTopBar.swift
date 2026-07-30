//
//  MeetingCallTopBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Top bar: minimize button

/// Top-left minimize chevron. Hang Up lives on the dedicated red button
/// at the bottom of the call — this button never ends the call, it
/// only shrinks it into the floating pill so the user can continue
/// browsing the app while the audio session keeps running.
struct MeetingCallTopBar: View {
    let onMinimizeTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onMinimizeTap) {
                Image(systemName: "chevron.compact.down")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(MeetingCallBrand.onSurface)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(MeetingCallBrand.surfaceHigh))
            }
            .accessibilityLabel("Minimize call")

            Spacer()
        }
    }
}
