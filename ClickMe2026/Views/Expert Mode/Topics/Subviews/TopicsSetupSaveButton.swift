//
//  TopicsSetupSaveButton.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupSaveButton: View {
    let viewModel: TopicsSetupViewModel

    var body: some View {
        AsyncSaveButton(
            title: "Save Changes",
            state: viewModel.isSaving ? .saving : (viewModel.didSave ? .saved : .idle),
            action: viewModel.save
        )
    }
}
