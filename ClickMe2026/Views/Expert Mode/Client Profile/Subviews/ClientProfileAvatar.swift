//
//  ClientProfileAvatar.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Photos-picker avatar with pulsing green ring and ambient glow

struct ClientProfileAvatar: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var profileImage: Image?
    let glowPulse: Bool

    var body: some View {
        ZStack {
            ambientGlow
            greenRing
            picker
        }
        .frame(width: 260, height: 200)
        .onChange(of: selectedPhoto) { item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data)
                {
                    withAnimation { profileImage = Image(uiImage: ui) }
                }
            }
        }
    }

    // MARK: Ambient glow

    private var ambientGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        ClientProfileBrand.brandGreen.opacity(glowPulse ? 0.32 : 0.12),
                        ClientProfileBrand.brandGreen.opacity(0.0),
                    ],
                    center: .center,
                    startRadius: 50,
                    endRadius: 130
                )
            )
            .frame(width: 260, height: 260)
            .blur(radius: 16)
            .animation(
                Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                value: glowPulse
            )
    }

    // MARK: Green ring

    private var greenRing: some View {
        Circle()
            .stroke(ClientProfileBrand.brandGreen, lineWidth: 3)
            .frame(width: 148, height: 148)
            .shadow(color: ClientProfileBrand.brandGreen.opacity(0.65), radius: 12, x: 0, y: 0)
    }

    // MARK: PhotosPicker

    private var picker: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            Group {
                if let image = profileImage {
                    image.resizable().scaledToFill()
                } else {
                    AsyncImage(url: URL(string: "https://randomuser.me/api/portraits/women/44.jpg")) { phase in
                        switch phase {
                        case let .success(img): img.resizable().scaledToFill()
                        default:
                            ZStack {
                                ClientProfileBrand.avatarFallback
                                Image(systemName: "person.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white.opacity(0.15))
                            }
                        }
                    }
                }
            }
            .frame(width: 142, height: 142)
            .clipShape(Circle())
        }
    }
}
