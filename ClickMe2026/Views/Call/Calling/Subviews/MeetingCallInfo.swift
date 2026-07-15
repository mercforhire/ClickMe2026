//
//  MeetingCallInfo.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Expert name + call timer + status label

struct MeetingCallInfo: View {
    let expertName: String
    let timerString: String
    let statusLabel: String

    var body: some View {
        VStack(spacing: 10) {
            Text(expertName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurface)

            Text(timerString)
                .font(.system(size: 22, weight: .regular, design: .monospaced))
                .foregroundColor(MeetingCallBrand.onSurfaceVar)

            Text(statusLabel)
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(MeetingCallBrand.onSurfaceVar)
        }
    }
}
