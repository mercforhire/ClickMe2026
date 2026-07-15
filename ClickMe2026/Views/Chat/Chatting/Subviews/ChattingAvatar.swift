//
//  ChattingAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Circular avatar with fallback

struct ChattingAvatar: View {
    let url: String
    let size: CGFloat

    var body: some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case let .success(img): img.resizable().scaledToFill()
            default:
                ZStack {
                    Color(red: 0.14, green: 0.20, blue: 0.16)
                    Image(systemName: "person.fill")
                        .font(.system(size: size * 0.45))
                        .foregroundColor(.white.opacity(0.15))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}
