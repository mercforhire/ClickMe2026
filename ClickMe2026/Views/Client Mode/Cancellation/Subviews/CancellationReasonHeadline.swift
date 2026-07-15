//
//  CancellationReasonHeadline.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Step 1 headline + subtitle

struct CancellationReasonHeadline: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why are you cancelling?")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(CancellationBrand.onSurface)

            Text("We're sorry to see you go. Please let us know the reason so we can improve our service.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(CancellationBrand.onSurfaceVar)
                .lineSpacing(4)
        }
    }
}
