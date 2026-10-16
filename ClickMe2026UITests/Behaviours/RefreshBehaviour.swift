//
//  RefreshBehaviour.swift
//  ClickMe2026UITests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Salad

struct RefreshHomeView: Behavior {
    func perform(from view: HomeView) -> HomeView {
        view.refreshButton.tap()
        return view
    }
}
