//
//  RequestDecisionMessageSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionMessageSection: View {
    let clientMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Message")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurface)

            Text(clientMessage)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(RequestDecisionTheme.onSurfaceMid)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(RequestDecisionTheme.cardBg))
        }
    }
}
