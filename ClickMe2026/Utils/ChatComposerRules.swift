//
//  ChatComposerRules.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Compile seam for the RED commit; replaced by the real rules in the GREEN commit.
nonisolated enum ChatComposerRules {
    static let limit = 0
    static let counterFrom = 0
    static func cap(_ raw: String) -> String { raw }
    static func showsCounter(length: Int) -> Bool { false }
    static func isAtLimit(length: Int) -> Bool { false }
    static func counterText(length: Int, locale: Locale = .current) -> String { "" }
    static func accessibilityCounterLabel(length: Int, locale: Locale = .current) -> String { "" }
    static func crossedLimit(oldLength: Int, newLength: Int) -> Bool { false }
}
