//
//  ExpertProfileSettingsSaveButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct ExpertProfileSettingsSaveButton: View {
    let viewModel: ExpertProfileSettingsViewModel

    var body: some View {
        AsyncSaveButton(
            title: "Save Changes",
            state: viewModel.isSaving ? .saving : (viewModel.didSave ? .saved : .idle),
            savedTitle: "Changes Saved!",
            action: viewModel.save
        )
    }
}
