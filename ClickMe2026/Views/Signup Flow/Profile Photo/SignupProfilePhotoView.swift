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

    let currentStep: Int = 1
    let totalSteps: Int = 4
    var onSave: (Image?) -> Void

    // MARK: Init

    init(
        viewModel: SignupProfilePhotoViewModel = SignupProfilePhotoViewModel(),
        onSave: @escaping (Image?) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
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
                        Text("Step \(currentStep) of \(totalSteps)")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.50))
                            .padding(.top, 28)
                            .padding(.bottom, 32)

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
        .onChange(of: viewModel.isSaved) { newValue in
            if newValue { onSave(viewModel.profileImage) }
        }
        .confirmationDialog("Remove photo?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                viewModel.removePhoto()
            }
            Button("Cancel", role: .cancel) {}
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
            .onChange(of: viewModel.selectedPhoto) { _ in
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
    SignupProfilePhotoView()
        .preferredColorScheme(.dark)
}
