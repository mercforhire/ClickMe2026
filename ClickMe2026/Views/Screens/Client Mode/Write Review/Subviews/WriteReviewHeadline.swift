//
//  WriteReviewHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - "How was your experience..." headline + subtitle

struct WriteReviewHeadline: View {
    let expertName: String

    var body: some View {
        VStack(spacing: 10) {
            Text("How was your experience\nwith \(expertName)?")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurface)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("Your feedback helps other users and experts.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(WriteReviewBrand.onSurfaceVar)
                .multilineTextAlignment(.center)
        }
    }
}
