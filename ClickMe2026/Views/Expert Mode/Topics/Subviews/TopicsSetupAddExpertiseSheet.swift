//
//  TopicsSetupAddExpertiseSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

struct TopicsSetupAddExpertiseSheet: View {
    let onAdd: (String) -> Void
    let onDismiss: () -> Void

    @State private var name: String = ""

    var body: some View {
        ZStack {
            TopicsSetupTheme.bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                Text("Add Expertise Area")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(TopicsSetupTheme.onSurface)
                    .frame(maxWidth: .infinity, alignment: .center)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Expertise Area")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(TopicsSetupTheme.onSurfaceVariant)
                    TextField("e.g. Product Management", text: $name)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                        .font(.system(size: 15))
                        .foregroundColor(TopicsSetupTheme.onSurface)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(TopicsSetupTheme.cardBg)
                                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(TopicsSetupTheme.outlineVariant.opacity(0.6), lineWidth: 1))
                        )
                }

                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(TopicsSetupTheme.onSurface)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TopicsSetupTheme.surfaceHigh)
                            )
                    }
                    Button { onAdd(name) } label: {
                        Text("Add")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(TopicsSetupTheme.onPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(TopicsSetupTheme.primary)
                            )
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                Spacer()
            }
            .padding(24)
        }
    }
}
