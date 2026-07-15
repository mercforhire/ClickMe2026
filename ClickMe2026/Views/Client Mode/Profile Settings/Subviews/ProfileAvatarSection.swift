//
//  ProfileAvatarSection.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Glowing avatar with photo picker overlay

struct ProfileAvatarSection: View {
    let profileImage: Image?
    @Binding var selectedPhoto: PhotosPickerItem?

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [ProfileSettingsBrand.brandGreen.opacity(0.35), .clear],
                    center: .center, startRadius: 50, endRadius: 110
                ))
                .frame(width: 220, height: 220)
                .blur(radius: 14)

            Circle()
                .stroke(ProfileSettingsBrand.brandGreen, lineWidth: 3)
                .frame(width: 140, height: 140)
                .shadow(color: ProfileSettingsBrand.brandGreen.opacity(0.60), radius: 10)

            Group {
                if let img = profileImage {
                    img.resizable().scaledToFill()
                } else {
                    AsyncImage(url: URL(string: "https://randomuser.me/api/portraits/women/44.jpg")) { phase in
                        switch phase {
                        case let .success(img): img.resizable().scaledToFill()
                        default:
                            ZStack {
                                Color(red: 0.10, green: 0.16, blue: 0.12)
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
            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                ZStack {
                    Circle()
                        .fill(ProfileSettingsBrand.brandGreen)
                        .frame(width: 38, height: 38)
                        .shadow(color: ProfileSettingsBrand.brandGreen.opacity(0.55), radius: 6)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(ProfileSettingsBrand.onPrimary)
                }
            }
            .offset(x: 2, y: 2)
        }
    }
}
