//
//  IncomingRequestAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct IncomingRequestAvatar: View {
    let request: BookingRequest

    var body: some View {
        ZStack {
            if request.isHighPriority {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Brand.primary,
                                Brand.primary.opacity(0.55),
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .shadow(color: Brand.primary.opacity(0.65), radius: 8)
                    .frame(width: 72, height: 72)
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.20), lineWidth: 2)
                    .frame(width: 72, height: 72)
            }

            AsyncImage(url: URL(string: request.clientImageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.12, green: 0.18, blue: 0.14)
                        Image(systemName: "person.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 65, height: 65)
            .clipShape(Circle())
        }
        .frame(width: 75, height: 75)
    }
}
