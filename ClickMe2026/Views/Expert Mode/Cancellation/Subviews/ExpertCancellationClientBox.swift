//
//  ExpertCancellationClientBox.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Client info box: avatar + name + topic + date + refund line

struct ExpertCancellationClientBox: View {
    let clientName: String
    let clientImageURL: String
    let sessionTopic: String
    let dateTime: String
    let refundType: String

    var body: some View {
        VStack(spacing: 0) {
            clientRow

            Rectangle()
                .fill(ExpertCancellationBrand.innerBorder.opacity(0.50))
                .frame(height: 1)
                .padding(.horizontal, 16)

            details
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ExpertCancellationBrand.innerBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ExpertCancellationBrand.innerBorder, lineWidth: 1)
                )
        )
    }

    // MARK: Client row

    private var clientRow: some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: clientImageURL)) { phase in
                switch phase {
                case let .success(img): img.resizable().scaledToFill()
                default:
                    ZStack {
                        ExpertCancellationBrand.avatarFallback
                        Image(systemName: "person.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.15))
                    }
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .overlay(Circle().stroke(ExpertCancellationBrand.brandGreen.opacity(0.30), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text(clientName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(ExpertCancellationBrand.onSurface)
                Text(sessionTopic)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(ExpertCancellationBrand.brandGreen)
            }
            Spacer()
        }
        .padding(16)
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(ExpertCancellationBrand.onSurfaceVar)
                    .frame(width: 20)
                Text(dateTime)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(ExpertCancellationBrand.onSurface)
            }

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "creditcard")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(ExpertCancellationBrand.onSurfaceVar)
                    .frame(width: 20)
                (
                    Text("A ")
                        .foregroundColor(ExpertCancellationBrand.onSurfaceVar)
                        + Text(refundType)
                        .foregroundColor(ExpertCancellationBrand.brandGreen)
                        .fontWeight(.semibold)
                        + Text(" will be processed to the client according to our policy.")
                        .foregroundColor(ExpertCancellationBrand.onSurface)
                )
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
    }
}
