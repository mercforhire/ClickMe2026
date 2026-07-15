//
//  ExpertProfileSettingsAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

struct ExpertProfileSettingsAvatar: View {
    @Bindable var viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        ZStack {
            // Glow aura
            Circle()
                .fill(RadialGradient(
                    colors: [
                        Brand.primary.opacity(0.38),
                        Brand.primary.opacity(0.0),
                    ],
                    center: .center, startRadius: 55, endRadius: 90
                ))
                .frame(width: 180, height: 180)
                .blur(radius: 10)

            // Border ring
            Circle()
                .stroke(Brand.primary, lineWidth: 3)
                .frame(width: 140, height: 140)
                .shadow(color: Brand.primary.opacity(0.60), radius: 10)

            // Photo
            Group {
                if let image = viewModel.profileImage {
                    image.resizable().scaledToFill()
                } else {
                    AsyncImage(url: URL(string: "https://randomuser.me/api/portraits/men/32.jpg")) { phase in
                        switch phase {
                        case let .success(img): img.resizable().scaledToFill()
                        default:
                            ZStack {
                                Color(red: 0.14, green: 0.20, blue: 0.15)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.15))
                            }
                        }
                    }
                }
            }
            .frame(width: 134, height: 134)
            .clipShape(Circle())
        }
        .frame(width: 180, height: 180)
        .overlay(alignment: .bottomTrailing) {
            editBadge
                .offset(x: 2, y: 2)
        }
        .onChange(of: viewModel.selectedPhoto) {
            Task { await viewModel.loadSelectedPhoto() }
        }
    }

    private var editBadge: some View {
        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.16, green: 0.20, blue: 0.17))
                    .frame(width: 36, height: 36)
                    .overlay(Circle().stroke(Brand.primary.opacity(0.60), lineWidth: 1))
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Brand.primary)
            }
        }
    }
}
