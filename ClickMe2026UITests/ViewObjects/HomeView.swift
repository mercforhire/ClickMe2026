//
//  HomeView.swift
//  ClickMe2026UITests
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Salad
import XCTest

struct HomeView: ViewObject {
    let root: XCUIElement
    let identifyingElementId: String = "HomeView"

    var userEmailLabel: XCUIElement {
        identifyingElement.staticTexts["userEmailLabel"]
    }

    var refreshButton: XCUIElement {
        identifyingElement.buttons["refreshButton"]
    }
}
