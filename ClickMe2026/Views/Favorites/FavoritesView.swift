//
//  FavoritesView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-15.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Model

struct FavoriteExpert: Identifiable {
    let id = UUID()
    let name: String
    let title: String
    let tags: [String]
    let rate: Int
    var isFavorited: Bool = true
    let imageURL: String
}

// MARK: - Sample data

extension FavoriteExpert {
    static let samples: [FavoriteExpert] = [
        FavoriteExpert(
            name: "Sarah Chen",
            title: "Senior UX Architect",
            tags: ["Design Systems", "Strategy"],
            rate: 185,
            imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBuLM2HFvVn5iq2xYO5dHjpK19mu_EIMDZPjqK9qMv_4k9iM8TChFmTqACEX1U1Y7seJaotE5worzC248lK7Bija0o6Tw1nGFJtipzoLhwviH12b31HWbNlk3JNpsQs78fDIYnmkZKldEXuJDsl9VUICiXpbHejktKaWMXUyhYQ9QP_GLQ4UCT-e7zH4a8nFpQ8zjDJvgXY56NSBf45xvhmZ-rzvdkzsAro7Nm_1dP0HWI8tm1sykwFW40ekKsX127tVbzJZTdbObM"
        ),
        FavoriteExpert(
            name: "Marcus Thorne",
            title: "Cloud Infrastructure",
            tags: ["AWS", "Kubernetes", "Scale"],
            rate: 240,
            imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuD-nTZU8wSeKxI4EW7zJy0Gv2v-RsBIIAcSheseVpLljNH-k--KoZ3pmHvSJ1Rigf4e8e3j6rP-o0AWyTvMeuh169-61S-ynIC2Zc8YOkA2VDH82IgGkoxsQ9FHKPwfuEuPs7D_Vfjq8AF83p5TTapVVktw_E5A13aoemf8lhTemXX-KNJchtUeCmwAoK55nrzD7lwAvQK_3tLcifHpqn9LEbwhmWdTRGVI7ssQm6CK-ex8IhaQwBb1rwoTuikKwNa8gF60MGQxQXw"
        ),
        FavoriteExpert(
            name: "Elena Rodriguez",
            title: "Growth Specialist",
            tags: ["Fintech", "Data Analysis"],
            rate: 165,
            imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuCKipx4syzb2qx7cf0gcpOViSNjuGT7uB9ZR4xfScfV5Em0YXfO_DhwVowgYsCdoZlhtAy4OebouU5QQxst1G07e2mT5BNUhV3ObL3opjtMnX5QgRs_0gA3rqyKslOoEfuYN8ieJG_s_coAA5Ov3ic1nzU3rfoXtZnhbpQUoMl_fvmEx3ieDQfv8cY7SvDokO7XBqB2PMo_Chqt13p0e6YmZ_FSBQZFRiAEd13YMjkvrBqnQasnr8iMSGxG8YBXPTrXuWsklyKgvU0"
        )
    ]
}

// MARK: - Favorites View

struct FavoritesView: View {

    // MARK: State
    @State private var experts: [FavoriteExpert]

    // MARK: Inits

    /// Production use — pre-loaded with sample experts
    init() {
        _experts = State(initialValue: FavoriteExpert.samples)
    }

    /// Preview / testing — inject any list; pass [] to force empty state
    init(experts: [FavoriteExpert]) {
        _experts = State(initialValue: experts)
    }

    // MARK: Computed
    private var visibleExperts: [FavoriteExpert] { experts.filter { $0.isFavorited } }

    // MARK: Colours
    private let brandGreen   = Color(red: 0.267, green: 0.965, blue: 0.592)  // #44f697
    private let bg           = Color(red: 0.075, green: 0.075, blue: 0.075)  // #131313
    private let cardBg       = Color(red: 0.071, green: 0.071, blue: 0.071).opacity(0.80)
    private let cardBorder   = Color(red: 0.173, green: 0.173, blue: 0.173)  // #2C2C2C
    private let tagBg        = Color(red: 0.208, green: 0.208, blue: 0.208)  // surface-container-highest
    private let onSurface    = Color(red: 0.898, green: 0.886, blue: 0.882)  // #e5e2e1
    private let onSurfaceVar = Color(red: 0.729, green: 0.796, blue: 0.737)  // #bacbbc
    private let errorColor   = Color(red: 1.000, green: 0.706, blue: 0.671)  // #ffb4ab
    private let onPrimary    = Color(red: 0.000, green: 0.224, blue: 0.114)  // #003920
    private let outlineVar   = Color(red: 0.235, green: 0.290, blue: 0.247)  // #3c4a3f

    // MARK: Body

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if visibleExperts.isEmpty {
                emptyState
                    .transition(.opacity)
            } else {
                contentList
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: visibleExperts.isEmpty)
    }

    // MARK: Content list

    private var contentList: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                sectionHeader
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                VStack(spacing: 12) {
                    ForEach(experts.indices, id: \.self) { i in
                        if experts[i].isFavorited {
                            expertCard(index: i)
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .animation(.easeInOut(duration: 0.3), value: visibleExperts.count)

                Spacer().frame(height: 32)
            }
        }
    }

    // MARK: Section header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(brandGreen)
                Text("Favorite Experts")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundColor(onSurface)
            }
            Text("Manage your curated list of elite professionals.")
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(onSurfaceVar)
        }
    }

    // MARK: Expert card

    private func expertCard(index: Int) -> some View {
        let expert = experts[index]

        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(cardBorder, lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 0) {

                // Top row
                HStack(alignment: .top, spacing: 14) {
                    avatarImage(url: expert.imageURL)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(expert.name)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(onSurface)
                        Text(expert.title)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(brandGreen)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            experts[index].isFavorited.toggle()
                        }
                    } label: {
                        Image(systemName: expert.isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(errorColor)
                            .padding(8)
                            .background(Circle().fill(Color.white.opacity(0.04)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 14)

                // Tags
                FlowLayout(spacing: 8) {
                    ForEach(expert.tags, id: \.self) { tag in tagChip(tag) }
                }
                .padding(.bottom, 20)

                // Rate + CTA
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HOURLY RATE")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                            .tracking(1.2)

                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text("$\(expert.rate)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(onSurface)
                            Text("/hr")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(onSurfaceVar)
                        }
                    }

                    Spacer()

                    Button { } label: {
                        Text("Book Session")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(onPrimary)
                            .padding(.horizontal, 22)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(brandGreen)
                                    .shadow(color: brandGreen.opacity(0.40), radius: 8, x: 0, y: 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Avatar

    private func avatarImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure, .empty:
                ZStack {
                    Color(red: 0.16, green: 0.18, blue: 0.18)
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.20))
                }
            @unknown default:
                Color(red: 0.16, green: 0.18, blue: 0.18)
            }
        }
        .frame(width: 64, height: 64)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(red: 0.235, green: 0.29, blue: 0.247), lineWidth: 1)
        )
    }

    // MARK: Tag chip

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(onSurfaceVar)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Capsule().fill(tagBg))
    }

    // MARK: Empty state

    private var emptyState: some View {
        EmptyFavoritesContent(brandGreen: brandGreen,
                              bg: bg,
                              onSurface: onSurface,
                              onSurfaceVar: onSurfaceVar,
                              outlineVar: outlineVar,
                              cardBg: cardBg,
                              cardBorder: cardBorder,
                              tagBg: tagBg,
                              onPrimary: onPrimary)
    }
}

// MARK: - Empty state subview

private struct EmptyFavoritesContent: View {

    let brandGreen: Color
    let bg: Color
    let onSurface: Color
    let onSurfaceVar: Color
    let outlineVar: Color
    let cardBg: Color
    let cardBorder: Color
    let tagBg: Color
    let onPrimary: Color

    @State private var glowPulse    = false
    @State private var iconScale: CGFloat  = 0.75
    @State private var iconOpacity: Double = 0
    @State private var bodyOpacity: Double = 0
    @State private var bodyOffset: CGFloat = 18

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {

                // ── Animated star illustration ──
                ZStack {
                    // Aura
                    Circle()
                        .fill(RadialGradient(
                            colors: [brandGreen.opacity(glowPulse ? 0.14 : 0.06), .clear],
                            center: .center, startRadius: 0, endRadius: 110
                        ))
                        .frame(width: 220, height: 220)
                        .blur(radius: 30)
                        .animation(Animation.easeInOut(duration: 2.4).repeatForever(autoreverses: true),
                                   value: glowPulse)

                    // Glass card
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(cardBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(cardBorder, lineWidth: 1)
                            )

                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(LinearGradient(
                                colors: [brandGreen.opacity(0.10), .clear],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))

                        Image(systemName: "star.fill")
                            .font(.system(size: 72))
                            .foregroundStyle(LinearGradient(
                                colors: [brandGreen, Color(red: 0.13, green: 0.85, blue: 0.53)],
                                startPoint: .top, endPoint: .bottom
                            ))
                            .shadow(color: brandGreen.opacity(0.60), radius: 15, x: 0, y: 0)

                        GeometryReader { geo in
                            Circle().fill(brandGreen.opacity(0.40)).frame(width: 8, height: 8)
                                .position(x: 20, y: 20)
                            Circle().fill(brandGreen.opacity(0.20)).frame(width: 12, height: 12)
                                .position(x: geo.size.width - 28, y: geo.size.height - 24)
                        }
                    }
                    .frame(width: 148, height: 148)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                }
                .frame(height: 200)
                .padding(.bottom, 28)

                // ── Headline ──
                Text("No favorites yet")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(onSurface)
                    .padding(.bottom, 10)

                // ── Subtitle ──
                Text("Start exploring and save your favorite experts to find them easily later.")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(onSurfaceVar)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 280)
                    .padding(.bottom, 28)

                // ── CTAs ──
                VStack(spacing: 14) {
                    Button { } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(brandGreen)
                                .shadow(color: brandGreen.opacity(0.30), radius: 20, x: 0, y: 4)
                                .frame(height: 56)
                            Text("Explore Experts")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(onPrimary)
                        }
                    }
                    .frame(height: 56)
                    .buttonStyle(FavScaleButtonStyle())

                    Button { } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.clear)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(outlineVar, lineWidth: 1)
                                )
                                .frame(height: 56)
                            Text("View My History")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(onSurface)
                        }
                    }
                    .frame(height: 56)
                    .buttonStyle(FavScaleButtonStyle())
                }
                .padding(.bottom, 36)

                // ── Pro Tip card ──
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(tagBg).frame(width: 40, height: 40)
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 18)).foregroundColor(brandGreen)
                    }
                    .fixedSize()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Pro Tip")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(onSurface)
                        Text("Tap the star icon on any expert's profile to add them to this list instantly.")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(onSurfaceVar)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(cardBorder, lineWidth: 1)
                        )
                )
            }
            .opacity(bodyOpacity)
            .offset(y: bodyOffset)
            .padding(.horizontal, 24)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.60, dampingFraction: 0.65).delay(0.15)) {
                iconScale = 1.0; iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.45).delay(0.30)) {
                bodyOpacity = 1; bodyOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { glowPulse = true }
        }
    }
}

// MARK: - Button style

private struct FavScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - FlowLayout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0; var rowX: CGFloat = 0; var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowX + size.width > width, rowX > 0 { height += rowH + spacing; rowX = 0; rowH = 0 }
            rowX += size.width + spacing; rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: height + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX = bounds.minX; var rowY = bounds.minY; var rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX, rowX > bounds.minX { rowY += rowH + spacing; rowX = bounds.minX; rowH = 0 }
            view.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            rowX += size.width + spacing; rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Previews

/// Three experts listed with live heart-toggle interaction
#Preview("With Content") {
    FavoritesView()
        .preferredColorScheme(.dark)
}

/// Animated star card, "Explore Experts" / "View My History" buttons, Pro Tip card
#Preview("Empty State") {
    FavoritesView(experts: [])
        .preferredColorScheme(.dark)
}
