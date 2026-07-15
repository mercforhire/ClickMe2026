//
//  AvailiabilitySaveButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct AvailiabilitySaveButton: View {
    let isSaving: Bool
    let didSave: Bool
    var onSave: () -> Void

    var body: some View {
        AsyncSaveButton(
            title: "Save changes",
            state: isSaving ? .saving : (didSave ? .saved : .idle),
            action: onSave
        )
    }
}
