//
//  ProfessionalDetailsSheet.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-17.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Professional Details Sheet

struct ProfessionalDetailsSheet: View {
    @Binding var jobTitle: String
    @Binding var company: String
    /// Optional binding for the expert's persistent Skype / Zoom / Meet
    /// link. Constant across bookings — see project memory
    /// `topic_price_semantics.md` for the wider "per-session" model
    /// discussion. Leave nil on the client-side settings screen (no such
    /// field there); expert-side settings passes a live binding.
    var meetingUrl: Binding<String>? = nil
    @Environment(\.dismiss) private var dismiss

    private let suggestedRoles = [
        "Marketing Specialist", "SEO Analyst", "Consultant",
        "Content Manager", "Social Media Manager",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Professional Details")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(ProfileSettingsBrand.onSurface)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 28)

            sheetField("Job Title", text: $jobTitle)
            sheetField("Company", text: $company)

            if let meetingUrl {
                meetingUrlField(text: meetingUrl)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Suggested Roles")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.onSurface)

                ProfileFlowLayout(spacing: 8) {
                    ForEach(suggestedRoles, id: \.self) { role in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { jobTitle = role }
                        } label: {
                            Text(role)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(ProfileSettingsBrand.onSurface)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.10, green: 0.16, blue: 0.12))
                                        .overlay(Capsule().stroke(
                                            ProfileSettingsBrand.brandGreen.opacity(jobTitle == role ? 0.70 : 0.25),
                                            lineWidth: 1
                                        ))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button { dismiss() } label: {
                    Text("Update")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onPrimary)
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Capsule().fill(ProfileSettingsBrand.brandGreen)
                            .shadow(color: ProfileSettingsBrand.brandGreen.opacity(0.45), radius: 10))
                }
                .buttonStyle(PressScaleButtonStyle())

                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(ProfileSettingsBrand.onSurface)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }

    /// URL-oriented variant of `sheetField` — turns off autocapitalization
    /// and autocorrection, and uses the URL keyboard so `.com`/`:`/`/`
    /// live above the letters. Uses `.URL` content type so iOS Keychain
    /// autofill can offer previously-typed URLs.
    private func meetingUrlField(text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text("Skype / Zoom link")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.brandGreen)
                TextField("e.g. zoom.us/j/1234567890", text: text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                    .tint(ProfileSettingsBrand.brandGreen)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .textContentType(.URL)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .frame(minHeight: 60)
    }

    private func sheetField(_ label: String, text: Binding<String>) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(ProfileSettingsBrand.fieldBg)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(ProfileSettingsBrand.fieldBorder, lineWidth: 1))
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.brandGreen)
                TextField("", text: text)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(ProfileSettingsBrand.onSurface)
                    .tint(ProfileSettingsBrand.brandGreen)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)
        }
        .frame(minHeight: 60)
    }
}
