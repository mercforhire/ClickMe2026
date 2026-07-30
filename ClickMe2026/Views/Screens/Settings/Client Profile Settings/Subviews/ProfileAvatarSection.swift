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
    /// Locally-picked, not-yet-uploaded image. Takes precedence over
    /// `remoteAvatarURL` so the user sees their new pick immediately.
    let profileImage: Image?
    /// URL of the server-stored avatar (from `UserManager.profile
    /// .personalDetails.avatarUrl`). Rendered when no local override
    /// is present. `nil` falls through to the person-fill silhouette.
    var remoteAvatarURL: String? = nil
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
                } else if let urlString = remoteAvatarURL,
                          !urlString.isEmpty,
                          let url = URL(string: urlString)
                {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(img): img.resizable().scaledToFill()
                        default: silhouette
                        }
                    }
                } else {
                    silhouette
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

    /// Neutral silhouette shown when no local pick AND no server URL is
    /// present (fresh account) or when the server image fails to load.
    private var silhouette: some View {
        ZStack {
            Color(red: 0.10, green: 0.16, blue: 0.12)
            Image(systemName: "person.fill")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.15))
        }
    }
}
