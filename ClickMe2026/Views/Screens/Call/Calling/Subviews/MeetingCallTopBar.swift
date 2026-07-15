//
//  MeetingCallTopBar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Top bar: dismiss (X) button

struct MeetingCallTopBar: View {
    let onDismissTap: () -> Void

    var body: some View {
        HStack {
            Button(action: onDismissTap) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(MeetingCallBrand.onSurface)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(MeetingCallBrand.surfaceHigh))
            }

            Spacer()
        }
    }
}
