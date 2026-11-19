//
//  ExpertProfileView.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-19.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
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
    /// Server flag mirroring `charges_enabled` for this expert. Defaults
    /// to true so we don't hide the Book button before the backend
    /// starts populating the field. When false, the profile view swaps
    /// the Book CTA for a "not accepting bookings" state.
    var isBookable: Bool = true
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

    /// True while the profile-report sheet is presented. The sheet calls
    /// the thread-independent `POST /users/:id/report` endpoint; see
    /// `docs/ios/USER-REPORTING.md` §1 and `ReportUserSheet`.
    @State private var showReportSheet: Bool = false

    /// Runs Block {name}: thread bootstrap, block action, toast and error text
    /// (CHAT-04, D-06). Report errors stay inside `ReportUserSheet`.
    @StateObject private var blockAction = ExpertProfileBlockViewModel()

    /// True while the `Block {name}?` confirmation alert is up. Nothing is sent
    /// until the alert's Block button is tapped.
    @State private var showBlockConfirm: Bool = false

    /// Shared nav path from the home shell (Explore / Search / Favorites
    /// all push this screen onto it). Used to push the booking flow on
    /// "Book Session" tap.
    @Environment(\.homeNavigationPath) private var navPath

    /// Shell-injected action that switches to the Chats tab and pushes
    /// a specific thread. Used by the "Message" button.
    @Environment(\.openChatThread) private var openChatThread

    /// Pops one level; the Back capsule of the not-available state.
    @Environment(\.dismiss) private var dismiss

    /// Optional caller-provided hook; if wired, it runs INSTEAD of the
    /// default push. Left as an escape hatch — no current caller uses
    /// it, so the default MakeABooking push is the effective behavior.
    var onBookSession: () -> Void
    var onMessage: () -> Void
    var onFavorite: () -> Void
    var onSeeAllReviews: () -> Void

    /// True when the current user IS the expert being displayed —
    /// i.e. the expert is viewing their own profile. Hides the CTAs
    /// (Book Session, Message, Favorite heart) that don't make sense
    /// against oneself, while keeping bio / topics / reviews visible
    /// so the expert can see how their profile appears to clients.
    var isSelfView: Bool

    /// Shortcut for the expert model exposed by the view model.
    private var expert: PublicExpertProfile { viewModel.expert }

    /// Defense-in-depth: `isSelfView` is caller-supplied and can be
    /// wrong (route forgets to pass it, auth transitions mid-view, …).
    /// Compare the profile id to the current session's user id at
    /// runtime so Report / Block never fire against the signed-in
    /// user — the backend will also 422 `CANNOT_REPORT_SELF`, but the
    /// client should never let the request leave.
    private var isSameAsCurrentUser: Bool {
        guard let expertId = expert.expertId,
              let currentId = UserManager.shared.me?.id
                  ?? UserManager.shared.authUser?.id
        else { return false }
        return expertId == currentId
    }

    // MARK: Init

    init(
        viewModel: ExpertProfileViewModel = ExpertProfileViewModel(),
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {},
        isSelfView: Bool = false
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onBookSession = onBookSession
        self.onMessage = onMessage
        self.onFavorite = onFavorite
        self.onSeeAllReviews = onSeeAllReviews
        self.isSelfView = isSelfView
    }

    /// Convenience init mirroring the original signature so existing call sites
    /// that pass an expert directly keep compiling.
    ///
    /// - Parameter isFavorited: The caller's best knowledge of the favorite
    ///   state, shown until the details load. The server's `is_favorite`
    ///   replaces it when they arrive (D-09). Only Favorites passes `true`.
    init(
        expert: PublicExpertProfile,
        isFavorited: Bool = false,
        onBookSession: @escaping () -> Void = {},
        onMessage: @escaping () -> Void = {},
        onFavorite: @escaping () -> Void = {},
        onSeeAllReviews: @escaping () -> Void = {},
        isSelfView: Bool = false
    ) {
        self.init(
            viewModel: ExpertProfileViewModel(expert: expert, isFavorited: isFavorited),
            onBookSession: onBookSession,
            onMessage: onMessage,
            onFavorite: onFavorite,
            onSeeAllReviews: onSeeAllReviews,
            isSelfView: isSelfView
        )
    }

    /// The heart and the overflow menu belong to a loaded (or still loading)
    /// profile; the not-available and load-failed states remove them.
    private var showsProfileActions: Bool {
        switch viewModel.loadState {
        case .loading, .loaded: true
        case .notFound, .failed: false
        }
    }

    // MARK: Body

    var body: some View {
        ZStack {
            ExpertProfileBrand.bg.ignoresSafeArea()

            switch viewModel.loadState {
            case .notFound:
                ExpertProfileStateView(kind: .notFound, onAction: { dismiss() })
            case .failed(let message):
                ExpertProfileStateView(
                    kind: .failed(message: message),
                    isWorking: viewModel.isRetrying,
                    onAction: { Task { await viewModel.retry() } }
                )
            case .loading, .loaded:
                profileScroll
            }
        }
        // Transparent nav bar so hero + scroll content shows through. Dark
        // color scheme keeps the back chevron / heart legible against the
        // Luminous-Dark palette.
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            // Favorite (heart) is a client action — hide when the
            // expert is viewing their own profile.
            if !isSelfView && showsProfileActions {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await viewModel.toggleFavorite()
                            onFavorite()
                        }
                    } label: {
                        Image(systemName: viewModel.isFavorited ? "heart.fill" : "heart")
                            .font(.title3.weight(.regular))
                            .foregroundColor(viewModel.isFavorited ? .red : ExpertProfileBrand.onSurface)
                    }
                    .disabled(viewModel.isFavoriteInFlight)
                    .accessibilityLabel(viewModel.isFavorited ? "Remove from favorites" : "Add to favorites")
                }

                // Overflow menu — App Review 1.2 requires an in-surface
                // path to report / block UGC. Report hits the dedicated
                // `/users/:id/report` endpoint (no chat required); Block
                // asks first, then goes through the thread-scoped
                // `chat_action` endpoint, bootstrapping a thread via
                // `/chats/initiate` on demand (`ExpertProfileBlockViewModel`).
                //
                // Also gate on `!isSameAsCurrentUser` so the signed-in
                // user never sees Report / Block pointed at themselves,
                // even if a caller forgets to set `isSelfView` (e.g.
                // viewing own profile via the shared `openChatThread`
                // or Explore cache). Backend 422s on `CANNOT_REPORT_SELF`
                // regardless, but the request should never leave.
                if !isSameAsCurrentUser {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                showReportSheet = true
                            } label: {
                                Label("Report This Profile", systemImage: "exclamationmark.bubble")
                            }
                            Button(role: .destructive) {
                                showBlockConfirm = true
                            } label: {
                                Label("Block \(expert.name)", systemImage: "hand.raised")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.title3.weight(.regular))
                                .foregroundColor(ExpertProfileBrand.onSurface)
                        }
                        .disabled(blockAction.isBlocking)
                        .accessibilityLabel("More options")
                    }
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            if let expertId = expert.expertId {
                ReportUserSheet(
                    userId: expertId,
                    userName: expert.name,
                    onSubmitted: { showReportSheet = false },
                    onDismiss: { showReportSheet = false }
                )
            }
        }
        // A centred alert, not a confirmation dialog: a Menu source would anchor a
        // dialog as an iPad popover (UI-SPEC section 6).
        .alert(
            "Block \(ExpertProfileBlockViewModel.displayName(expert.name))?",
            isPresented: $showBlockConfirm
        ) {
            Button("Block", role: .destructive) {
                guard let expertId = expert.expertId,
                      !isSameAsCurrentUser  // belt-and-suspenders: menu is already gated
                else { return }
                blockAction.block(peerId: expertId, peerName: expert.name)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("They won't be able to message you.")
        }
        .alert(
            "Couldn't block user",
            isPresented: Binding(
                get: { blockAction.apiError != nil },
                set: { if !$0 { blockAction.apiError = nil } }
            ),
            presenting: blockAction.apiError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        // In-flight scrim while Block runs: absorbs taps, one VoiceOver element
        // labelled "Blocking" with the modal trait (UI-SPEC section 6, Accessibility).
        .overlay {
            if blockAction.isBlocking {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture {}
                    ProgressView()
                        .controlSize(.large)
                        .tint(Brand.primary)
                }
                .accessibilityElement()
                .accessibilityLabel("Blocking")
                .accessibilityAddTraits(.isModal)
            }
        }
        .onAppear { viewModel.glowPulse = true }
        .task { await viewModel.loadProfileDetails() }
        .navigationDestination(isPresented: $showReviews) {
            ExpertReviewsView(expertId: expert.expertId, expertName: expert.name)
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
        .alert(
            "Couldn't start chat",
            isPresented: presenting(\.messageError),
            presenting: viewModel.messageError
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { message in
            Text(message)
        }
    }

    /// The profile content, shown while loading (seeded) and once loaded.
    private var profileScroll: some View {
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

                // Book / Message CTAs are for clients — hide when
                // the expert is viewing their own profile.
                if !isSelfView {
                    ExpertProfileActionButtons(
                        onBookSession: handleBookSession,
                        onMessage: handleMessage,
                        isBookable: expert.isBookable
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }

                ExpertProfileAboutCard(bio: expert.bio)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)

                // EXPL-02: an empty section is not drawn, and its bottom
                // padding goes with it, so no bare header or blank gap stays.
                if ExpertProfileSections.showsExpertise(expert.expertiseTags) {
                    ExpertProfileExpertiseSection(tags: expert.expertiseTags)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }

                if ExpertProfileSections.showsTopics(expert.topics) {
                    ExpertProfileTopicsCard(topics: expert.topics)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }

                if ExpertProfileSections.showsReviews(expert.reviews) {
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
    /// thread. No-ops without an expertId (preview / placeholder data) or when
    /// no ambient shell action is installed. A failed call raises an alert.
    private func handleMessage() {
        onMessage()
        guard expert.expertId != nil, let openChatThread else { return }

        Task {
            // A failure raises the "Couldn't start chat" alert through `messageError` (WR-12).
            guard let threadId = await viewModel.startChat() else { return }
            openChatThread(
                threadId: threadId,
                peerName: expert.name,
                peerAvatarURL: expert.imageURL
            )
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
                    .font(.title.weight(.light))
                    .foregroundColor(.white.opacity(0.6))
                Text("Preview bootstrap failed")
                    .font(.brand(.subheadline, weight: .semibold))
                    .foregroundColor(.white)
                Text(errorMessage)
                    .font(.brand(.caption))
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
