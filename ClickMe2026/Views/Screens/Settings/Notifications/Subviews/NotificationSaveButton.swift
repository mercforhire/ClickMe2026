//
//  NotificationSaveButton.swift
//  ClickMe2026
//

import SwiftUI

struct NotificationSaveButton: View {
    let isSaving: Bool
    let didSave: Bool
    let action: () -> Void

    var body: some View {
        AsyncSaveButton(
            title: "Save Changes",
            state: isSaving ? .saving : (didSave ? .saved : .idle),
            action: action
        )
    }
}
