//
//  SignupProfilePhotoView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-14.
//  Copyright © 2026 Q42. All rights reserved.
//

import PhotosUI
import SwiftUI

// MARK: - Profile Picture Setup Screen (Step 2 of 4)

struct SignupProfilePhotoView: View {

    @StateObject private var viewModel: SignupProfilePhotoViewModel

    // UI-only state
    @State private var showRemoveConfirm: Bool = false
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 16

    var onSave: (Image?) -> Void

    // MARK: Init

    init(
        viewModel: SignupProfilePhotoViewModel = SignupProfilePhotoViewModel(),
        onSave: @escaping (Image?) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSave = onSave
    }

    /// Runtime init — uploads via `POST /user/profile/avatar` and mirrors
    /// the returned URL onto the shared `SignupAccumulator`.
    init(
        accumulator: SignupAccumulator,
        onSave: @escaping (Image?) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: SignupProfilePhotoViewModel(accumulator: accumulator))
        self.onSave = onSave
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ProfilePhotoBrand.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                ProfilePhotoHeader()

                Divider()
                    .background(Color.white.opacity(0.08))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ProfileAvatarRing(
                            image: viewModel.profileImage,
                            zoomScale: viewModel.zoomScale
                        )
                        .padding(.bottom, 36)

                        ProfilePhotoZoomSlider(
                            zoomScale: $viewModel.zoomScale,
                            isEnabled: viewModel.hasPhoto
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)

                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, 28)

                        ProfilePhotoSaveButton(isLoading: viewModel.isSaving) {
                            Task { await viewModel.save() }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .opacity(contentOpacity)
        .offset(y: contentOffset)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
        }
        .onChange(of: viewModel.isSaved) { _, newValue in
            if newValue { onSave(viewModel.profileImage) }
        }
        .confirmationDialog("Remove photo?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                viewModel.removePhoto()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert(
            "Couldn't upload photo",
            isPresented: Binding(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            ),
            presenting: viewModel.saveError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    // MARK: Action buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $viewModel.selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            ) {
                PhotoActionButtonLabel(icon: "camera", title: "Upload Photo")
            }
            .onChange(of: viewModel.selectedPhoto) {
                Task { await viewModel.loadSelectedPhoto() }
            }

            Button { showRemoveConfirm = true } label: {
                PhotoActionButtonLabel(icon: "trash", title: "Remove Photo")
            }
            .disabled(!viewModel.hasPhoto)
            .opacity(viewModel.hasPhoto ? 1 : 0.40)
        }
    }
}

// MARK: - Previews

#Preview("Default — No Photo") {
    PreviewNavHarness(parentText: "Complete your profile", navTitle: "Profile setup", rowTitle: "Add profile picture") {
        SignupProfilePhotoView()
    }
    .preferredColorScheme(.dark)
}
