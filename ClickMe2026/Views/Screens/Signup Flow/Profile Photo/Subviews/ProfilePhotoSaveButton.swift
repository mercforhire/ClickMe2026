//
//  ProfilePhotoSaveButton.swift
//  ClickMe2026
//

import SwiftUI

struct ProfilePhotoSaveButton: View {
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        AsyncSaveButton(
            title: "Save",
            state: isLoading ? .saving : .idle,
            action: action
        )
    }
}
