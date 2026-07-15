//
//  TagsDoneButton.swift
//  ClickMe2026
//

import SwiftUI

/// Brand-green pill "Done" button.
struct TagsDoneButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(TagsBrand.green)
                    .shadow(color: TagsBrand.green.opacity(0.45), radius: 14, x: 0, y: 6)
                    .frame(height: 56)

                Text("Done")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 56)
    }
}
