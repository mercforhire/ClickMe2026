//
//  ModeSwitchView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-16.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Mode model

enum AppMode: CaseIterable {
    case client, expert

    var title: String       { self == .client ? "Client Mode"  : "Expert Mode" }
    var subtitle: String    { self == .client ? "Find and book experts" : "Manage bookings and profile" }
    var description: String {
        self == .client
            ? "Browse a wide range of experts and book sessions that fit your needs."
            : "Manage your bookings, update your profile, and connect with clients."
    }
    var imageURL: String {
        self == .client
            ? "https://lh3.googleusercontent.com/aida-public/AB6AXuDI3SjPbx21Wdts7TMWgv_CqWdtUcqwuPXaXHb9DMU2O0Rljn0pm0O-kl0E0wIkcBKpf6s5u1wPq4jfo046C7jwHNU7pgnf79_g9alalALh7okJUcVmXqij8Bzi-SUpwJpNeBGRWBwYmor0scCIkT5QNPawfjd9q__Sw0C6wJcbiyqgVrHiSA2i2UvIr9bF9tbRQ93OxVENLBYd9EtqxLljRg8YVJEFMUmHaHIsjklbRxuDNbtaa8_aIeC-Gbjp1Xf7mH8JNEU2WIg"
            : "https://lh3.googleusercontent.com/aida-public/AB6AXuCjVb8uP0KYBs2wBlIAtZbo2N5YedP7bxXIu4lh2IQXx6o0UvKCwgjFz7VIsKgTAcGDowTOarvSRsUItcRjHdewbqsSoH-p_jZZ7VfMJmdWyUneMYbgjhIFHvBfNHYuXb1-kQzSRvCCsE-CtEzg1Dh8wIEaeURwlZPBQEfFtBMk4pzstItnSv-s07X-3w4Hl54DQ6AfKcdRAtCCj5BqgNdRBCZkGvVnV1GqkmVQchWUBS2J3f5I7XqppPsfmaTkkJJoKwKhEHIzafk"
    }
}

// MARK: - Mode Switcher View

struct ModeSwitchView: View {

    @State private var selectedMode: AppMode = .client
    @Environment(\.dismiss) private var dismiss

    var onConfirm: (AppMode) -> Void

    // MARK: Colours
    private let brandGreen  = Color(red: 0.220, green: 0.878, blue: 0.482)   // #38e07b
    private let bgDark      = Color(red: 0.071, green: 0.126, blue: 0.090)   // #122017
    private let cardActive  = Color(red: 0.071, green: 0.126, blue: 0.090)
    private let cardIdle    = Color(red: 0.071, green: 0.071, blue: 0.071).opacity(0.85)
    private let borderIdle  = Color(red: 0.200, green: 0.200, blue: 0.200)
    private let textPrimary = Color(red: 0.949, green: 0.949, blue: 0.961)   // zinc-100
    private let textSub     = Color(red: 0.600, green: 0.620, blue: 0.620)   // zinc-400
    private let textMuted   = Color(red: 0.420, green: 0.430, blue: 0.430)   // zinc-500

    // MARK: Init
    init(onConfirm: @escaping (AppMode) -> Void = { _ in }) {
        self.onConfirm = onConfirm
    }

    // MARK: Body

    var body: some View {
        ZStack {
            bgDark.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Nav bar ──
                navBar
                    .padding(.bottom, 20)

                // ── Mode cards ──
                VStack(spacing: 14) {
                    ForEach(AppMode.allCases, id: \.title) { mode in
                        modeCard(mode)
                    }
                }
                .padding(.horizontal, 16)

                Spacer()

                // ── Confirm button ──
                confirmButton
                    .padding(.horizontal, 16)
                    .padding(.bottom, 36)
            }
        }
    }

    // MARK: Nav bar

    private var navBar: some View {
        ZStack {
            Text("Mode Switcher")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(textPrimary)

            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textPrimary)
                        .frame(width: 40, height: 40)
                }
                Spacer()
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .overlay(
            Divider()
                .background(Color(red: 0.15, green: 0.15, blue: 0.15)),
            alignment: .bottom
        )
        .padding(.bottom, 1)
    }

    // MARK: Mode card

    private func modeCard(_ mode: AppMode) -> some View {
        let isActive = selectedMode == mode

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedMode = mode
            }
        } label: {
            ZStack(alignment: .topTrailing) {
                // Card background + border
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isActive ? brandGreen.opacity(0.15) : cardIdle)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(isActive ? brandGreen : borderIdle, lineWidth: isActive ? 1.5 : 1)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isActive)

                // Card content
                HStack(alignment: .top, spacing: 14) {
                    // Illustration
                    AsyncImage(url: URL(string: mode.imageURL)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                        default:
                            ZStack {
                                Color(red: 0.14, green: 0.18, blue: 0.15)
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.15))
                            }
                        }
                    }
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    // Text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(mode.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(textPrimary)

                        Text(mode.subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(textSub)

                        Text(mode.description)
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(textMuted)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)

                // "Active" badge — top-right
                if isActive {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(brandGreen)
                            .frame(width: 10, height: 10)
                        Text("Active")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(brandGreen)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
        }
        .buttonStyle(ModeScaleButtonStyle())
    }

    // MARK: Confirm button

    private var confirmButton: some View {
        Button { onConfirm(selectedMode) } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(brandGreen)
                    .shadow(color: brandGreen.opacity(0.35), radius: 14, x: 0, y: 4)
                    .frame(height: 54)

                Text("Continue as \(selectedMode == .client ? "Client" : "Expert")")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.00, green: 0.22, blue: 0.09))
                    .animation(.none, value: selectedMode)
            }
        }
        .frame(height: 54)
        .buttonStyle(ModeScaleButtonStyle())
    }
}

// MARK: - Button style

private struct ModeScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Previews

#Preview("Client Active") {
    ModeSwitchView()
        .preferredColorScheme(.dark)
}

#Preview("Expert Active") {
    ExpertModePreview()
        .preferredColorScheme(.dark)
}

private struct ExpertModePreview: View {
    @State private var view = ModeSwitchView()
    var body: some View {
        ModeSwitchView()
            .onAppear { }   // tap Expert card in canvas to see its state
    }
}
