//
//  CustomTagSection.swift
//  ClickMe2026
//

import SwiftUI

/// "Add your own tag" section with a TextField and a "+" submit button.
struct CustomTagSection: View {
    @Binding var text: String
    let onAdd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Can't find a tag? Add your own.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(Color.white.opacity(0.38))

            HStack(spacing: 10) {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text("Enter custom tag")
                            .foregroundColor(Color.white.opacity(0.28))
                            .font(.system(size: 16, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .font(.system(size: 16, design: .rounded))
                    .autocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(onAdd)

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(text.isEmpty ? Color.white.opacity(0.25) : TagsBrand.green)
                }
                .disabled(text.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(TagsBrand.fieldBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(TagsBrand.fieldBorder, lineWidth: 1)
                    )
            )
        }
    }
}
