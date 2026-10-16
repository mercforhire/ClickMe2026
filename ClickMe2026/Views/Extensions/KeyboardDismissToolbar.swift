//
//  KeyboardDismissToolbar.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

/// Adds a "Done" button to the input-accessory bar on every keyboard
/// raised inside the modified view tree.
///
/// Attached at the app root (`ClickMe2026App`) so it applies to all
/// text inputs — `TextField`, `TextEditor`, `SecureField` — without
/// each screen having to opt in. The button uses the responder-chain
/// `resignFirstResponder` action, so it dismisses whichever field is
/// currently focused without needing per-view `@FocusState` plumbing.
///
/// Where this matters most:
/// - Multi-line `TextEditor` (private notes, feedback, cancellation
///   reasons, reschedule messages): Return inserts a newline, so
///   there's otherwise no way to dismiss short of tapping outside.
/// - Numeric-keypad fields, which have no Return key at all.
///
/// If a specific screen needs its own toolbar (custom buttons, tab-
/// between-fields, etc.) it can override by attaching its own
/// `.toolbar(placement: .keyboard)` further down the tree.
struct KeyboardDismissToolbarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil,
                        from: nil,
                        for: nil
                    )
                } label: {
                    Text("Done")
                        .font(.brand(.subheadline, weight: .semibold))
                }
                Spacer()
            }
        }
    }
}

extension View {
    func keyboardDismissToolbar() -> some View {
        modifier(KeyboardDismissToolbarModifier())
    }
}
