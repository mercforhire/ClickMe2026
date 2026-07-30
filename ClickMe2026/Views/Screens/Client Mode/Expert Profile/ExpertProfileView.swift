//
//  ExpertProfileView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

// MARK: - Models

struct PublicExpertProfile {
    /// Server-issued expert UUID. Optional because we may construct a
    /// profile from hardcoded sample data that has no real backing. Required
    /// for calling `/client/favorites/:expertId`.
    let expertId: UUID?
    let name: String
    let title: String
    let rating: Double
    let reviewCount: Int
    let yearsExp: String
    let bookings: String
    let isOnline: Bool
    let bio: String
    let expertiseTags: [PublicExpertTag]
    let topics: [PublicTopic]
    let reviews: [PublicReview]
    let imageURL: String
}

struct PublicExpertTag {
    let label: String
    let isHighlighted: Bool
}

struct PublicTopic {
    let title: String
    let duration: String
    let description: String
    let price: String
    let isFree: Bool
}

struct PublicReview {
    let reviewer: String
    let stars: Int
    let body: String
}

// MARK: - Expert Public Profile View

struct ExpertProfileView: View {

    @StateObject private var viewModel: ExpertProfileViewModel

    /// Push-state for the reviews screen. Set by the "See all reviews" tap
    /// and observed by `.navigationDestination(isPresented:)`, which
    /// piggybacks on whichever `NavigationStack` this profile is inside.
    @State private var showReviews: Bool = false

    /// Shared nav path from the home shell (Explore / Search / Favorites
    /// all push this screen onto it). Used to push the booking flow on
    /// "Book Session" tap.
    @Environment(\.homeNavigationPath) private var navPath

    /// Shell-injected action that switches to the Chats tab and pushes
    /// a specific thread. Used by the "Message" button.
    @Environment(\.openChatThread) private var openChatThread

    /// Optional caller-provided hook; if wired, it runs INSTEAD of the
    /// default push. Left as an escape hatch — no current caller uses
    /// it, so the default MakeABooking push is the effective behavior.
    var onBookSession: () -> Void
    var onMessage: () -> Void
    var onFavorite: () -> Void
    var onSeeAllReviews: () -> Void

    /// Shortcut for the expert model exposed by the view model.
    private var expert: PublicExpertProfile { viewModel.expert }

    // MARK: Init

    init(
        viewModel: ExpertProfileViewModel = ExpertProfileViewModel(),
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookSession = onBookSession
        self.onMessage = onMessage
        self.onFavorite = onFavorite
        self.onSeeAllReviews = onSeeAllReviews
    }

    /// Convenience init mirroring the original signature so existing call sites
    /// that pass an expert directly keep compiling.
    init(
        expert: PublicExpertProfile,
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {}
    ) {
        self.init(
            viewModel: ExpertProfileViewModel(expert: expert),
            onBookSession: onBookSession,
            onMessage: onMessage,
            onFavorite: onFavorite,
            onSeeAllReviews: onSeeAllReviews
        )
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertProfileBrand.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ExpertProfileHero(
                        expert: expert,
                        glowPulse: viewModel.glowPulse,
                        summaryLoaded: viewModel.isSummaryLoaded
                    )
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                    ExpertProfileStatsBar(
                        yearsExp: expert.yearsExp,
                        bookings: expert.bookings
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)

                    ExpertProfileActionButtons(
                        onBookSession: handleBookSession,
                        onMessage: handleMessage
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                    ExpertProfileAboutCard(bio: expert.bio)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileExpertiseSection(tags: expert.expertiseTags)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileTopicsCard(topics: expert.topics)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                    ExpertProfileReviewsCard(
                        reviews: expert.reviews,
                        onSeeAllReviews: {
                            showReviews = true
                            onSeeAllReviews()
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 48)
                }
            }
        }
        // Transparent nav bar so hero + scroll content shows through. Dark
        // color scheme keeps the back chevron / heart legible against the
        // Luminous-Dark palette.
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.toggleFavorite()
                        onFavorite()
                    }
                } label: {
                    Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(viewModel.isFavorited ? .red : ExpertProfileBrand.onSurface)
                }
                .disabled(viewModel.isFavoriteInFlight)
                .accessibilityLabel(viewModel.isFavorited ? "Remove from favorites" : "Add to favorites")
            }
        }
        .onAppear { viewModel.glowPulse = true }
        .task { await viewModel.loadProfileDetails() }
        .navigationDestination(isPresented: $showReviews) {
            ExpertReviewsView(expertId: expert.expertId)
        }
        // "Book Session" pushes the booking flow onto the same NavStack.
        // Reuses `BookAgainSeed` since its four fields match exactly what
        // `MakeABooking` needs — despite the "book again" name, the type
        // is a general seed for the booking-flow entry point.
        .navigationDestination(for: BookAgainSeed.self) { seed in
            MakeABooking(
                expertId: seed.expertId,
                expertName: seed.expertName,
                expertTitle: seed.expertTitle,
                expertImageURL: seed.expertImageURL
            )
        }
        .alert(
            "Couldn't update favorites",
            isPresented: presenting(\.apiError),
            presenting: viewModel.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    /// Binding that's `true` while `apiError` is non-nil; setting it to
    /// `false` clears the error and dismisses the alert.
    private func presenting(_ keyPath: ReferenceWritableKeyPath<ExpertProfileViewModel, String?>) -> Binding<Bool> {
        Binding(
            get: { viewModel[keyPath: keyPath] != nil },
            set: { if !$0 { viewModel[keyPath: keyPath] = nil } }
        )
    }

    /// Book Session tap handler. Runs the caller-provided `onBookSession`
    /// hook if any, then pushes `MakeABooking` onto the ambient shell
    /// nav stack via `BookAgainSeed`. Silently no-ops when the expert
    /// has no `expertId` (preview seeds / placeholder data) since the
    /// backend can't book against a nil id.
    private func handleBookSession() {
        onBookSession()
        guard let expertId = expert.expertId else { return }
        let seed = BookAgainSeed(
            expertId: expertId,
            expertName: expert.name,
            expertTitle: expert.title,
            expertImageURL: expert.imageURL
        )
        if let navPath {
            navPath.push(seed)
        }
    }

    /// Message tap handler. Fires `onMessage` (caller escape hatch),
    /// then calls `POST /chats/initiate` to get or create a thread with
    /// this expert and asks the shell to open the Chats tab + push the
    /// thread. Silently no-ops without an expertId (preview / placeholder
    /// data) or when no ambient shell action is installed.
    private func handleMessage() {
        onMessage()
        guard let expertId = expert.expertId,
              let openChatThread
        else { return }

        Task {
            do {
                let response = try await ClickMeAPI.shared.initiateChat(peerId: expertId)
                openChatThread(
                    threadId: response.data.threadId,
                    peerName: expert.name,
                    peerAvatarURL: expert.imageURL
                )
            } catch {
                // Silent — the caller's expected UX is a thread appearing.
                // On failure the user can retry from the Chats tab.
                // TODO: surface via viewModel.apiError once we have a
                // dedicated messaging error state distinct from favorite
                // toggling.
            }
        }
    }
}

// MARK: - Placeholder

extension PublicExpertProfile {
    /// Empty profile used as a safe initial value before real data lands.
    /// Callers that construct a profile from a display type (Explore card,
    /// Search result, Favorite card) start from `.placeholder` and overlay
    /// what they know; `ExpertProfileViewModel.loadProfileDetails()` then
    /// refreshes bio / stats / topics from `/experts/:id/details`.
    static let placeholder = PublicExpertProfile(
        expertId: nil,
        name: "",
        title: "",
        rating: 0,
        reviewCount: 0,
        yearsExp: "",
        bookings: "",
        isOnline: false,
        bio: "",
        expertiseTags: [],
        topics: [],
        reviews: [],
        imageURL: ""
    )
}

// MARK: - Previews

/// Live-fetch preview. Bootstraps by calling `/client/home` to pick a real
/// recommended expert, seeds the profile from that row (including
/// `is_favorite`), then lets the view's own `.task` refresh bio/topics via
/// `/experts/:id/details`. Tapping the heart fires real `PUT`/`DELETE`
/// `/client/favorites/:id` and reconciles with the response.
///
/// Requires `PreviewSecrets.clientBearerToken` to hold a valid client-role JWT.
#Preview("Live Fetch") {
    PreviewNavHarness(parentText: "Search results", navTitle: "Experts", rowTitle: "View expert") {
        LiveFetchProfileBootstrap()
    }
    .preferredColorScheme(.dark)
}

/// Custom async bootstrap that pulls a real expert from `/client/home`
/// then hands off to `ExpertProfileView`.
private struct LiveFetchProfileBootstrap: View {
    @State private var seed: PublicExpertProfile?
    @State private var initialFavorite: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        if let seed {
            ExpertProfileView(
                viewModel: ExpertProfileViewModel(
                    expert: seed,
                    isFavorited: initialFavorite
                )
            )
        } else if let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ExpertProfileBrand.bg.ignoresSafeArea())
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(ExpertProfileBrand.bg.ignoresSafeArea())
                .task { await bootstrap() }
        }
    }

    private func bootstrap() async {
        ClickMeAPI.shared.bearerToken = PreviewSecrets.clientBearerToken
        do {
            let home = try await ClickMeAPI.shared.getClientHome()
            guard let re = home.data.recommendedExperts.first else {
                errorMessage = "No recommended experts in the home feed to preview."
                return
            }
            seed = PublicExpertProfile(
                expertId: re.expertId,
                name: re.fullName ?? "Expert",
                title: re.title ?? "",
                rating: re.rating ?? 0,
                reviewCount: re.reviewCount ?? 0,
                yearsExp: re.yearsExperience.map { "\($0) Yrs" } ?? "",
                bookings: "",
                isOnline: true,
                bio: "",
                expertiseTags: (re.expertiseTags ?? []).map {
                    PublicExpertTag(label: $0, isHighlighted: false)
                },
                topics: [],
                reviews: [],
                imageURL: re.profileImageUrl ?? ""
            )
            initialFavorite = re.isFavorite
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
