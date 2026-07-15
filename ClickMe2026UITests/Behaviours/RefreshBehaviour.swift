//
//  RefreshBehaviour.swift
//  ClickMe2026UITests
//
//  Copyright © 2024 Q42. All rights reserved.
//

import Foundation
import Salad

struct RefreshHomeView: Behavior {
    func perform(from view: HomeView) -> HomeView {
        view.refreshButton.tap()
        return view
    }
}
