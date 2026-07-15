//
//  RequestDecisionClientHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct RequestDecisionClientHeader: View {
    let request: IncomingRequest
    var onViewProfile: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            AsyncImage(url: URL(string: request.imageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        Color(red: 0.14, green: 0.20, blue: 0.16)
                        Image(systemName: "person.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(request.clientName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(RequestDecisionTheme.onSurface)

                Button(action: onViewProfile) {
                    Text("View Profile")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(RequestDecisionTheme.brandGreen)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
