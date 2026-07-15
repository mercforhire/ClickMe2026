//
//  PlaceholderModifier.swift
//  ClickMe2026
//

import SwiftUI

extension View {
    /// Overlays `placeholder` underneath the view while `condition` is true.
    func placeholder<Content: View>(
        when condition: Bool,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: .leading) {
            if condition { placeholder() }
            self
        }
    }
}

