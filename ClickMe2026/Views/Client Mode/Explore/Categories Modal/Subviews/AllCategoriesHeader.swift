//
//  AllCategoriesHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-22.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Drag indicator + title + close button

struct AllCategoriesHeader: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 20)

            HStack {
                Text("All Categories")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AllCategoriesBrand.onSurface)

                Spacer()

                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.10))
                            .frame(width: 32, height: 32)
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(AllCategoriesBrand.onSurface)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}
