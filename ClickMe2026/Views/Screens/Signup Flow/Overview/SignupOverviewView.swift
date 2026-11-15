//
//  ProfileOnboardingView.swift
//  ClickMe
//
//  Expert "Complete Your Profile" onboarding overview.
//  Luminous Dark design system. Bottom tab bar intentionally omitted.
//
//  Deployment target: iOS 16+
//

import SwiftUI

// MARK: - Models

enum ChecklistItemKind: Hashable {
    case basicInfo
    case timezone
    case profilePicture
    case verifyEmail
    case expertise
}

struct ChecklistItem: Identifiable {
    let id = UUID()
    let kind: ChecklistItemKind
    let title: String
    let isComplete: Bool
}

struct ProfileTip: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

// MARK: - Screen

struct SignupOverviewView: View {

    @StateObject private var viewModel: SignupOverviewViewModel

    var onNext: () -> Void
    var onChecklistItemTap: (ChecklistItem) -> Void

    /// The hub's exit (D-01, SIGN-06). When set, the back chevron and the
    /// swipe-back are removed and a leading "Not now" button takes their
    /// place, so the hub never traps the user. Previews leave it nil.
    var onNotNow: (() -> Void)?

    // UI-only animation state
    @State private var animatedProgress = 0.0

    init(
        viewModel: SignupOverviewViewModel = SignupOverviewViewModel(),
        onNext: @escaping () -> Void = {},
        onChecklistItemTap: @escaping (ChecklistItem) -> Void = { _ in },
        onNotNow: (() -> Void)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
        self.onChecklistItemTap = onChecklistItemTap
        self.onNotNow = onNotNow
    }

    /// Runtime init — the checklist tracks the accumulator's progress
    /// automatically as the user completes earlier steps.
    init(
        accumulator: SignupAccumulator,
        onNext: @escaping () -> Void = {},
        onChecklistItemTap: @escaping (ChecklistItem) -> Void = { _ in },
        onNotNow: (() -> Void)? = nil
    ) {
        self.init(
            viewModel: SignupOverviewViewModel(accumulator: accumulator),
            onNext: onNext,
            onChecklistItemTap: onChecklistItemTap,
            onNotNow: onNotNow
        )
    }

    var body: some View {
        ZStack {
            Brand.surface.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    OverviewHeader()

                    OverviewProgressBar(
                        progress: viewModel.progress,
                        animatedProgress: animatedProgress
                    )
                    .padding(.top, 28)

                    VStack(spacing: 14) {
                        ForEach(viewModel.checklist) { item in
                            OverviewChecklistRow(item: item) {
                                onChecklistItemTap(item)
                            }
                        }
                    }
                    .padding(.top, 24)

                    OverviewTipsCard(tips: viewModel.tips)
                        .padding(.top, 32)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .bottom) {
            OverviewNextBar(action: onNext)
        }
        // The hub's toolbar button uses a dark-surface colour. Without a dark bar
        // trait the iOS 26 glass capsule turns light grey in Light appearance
        // with opaque glass (G-05-1); same pins as the sibling signup screens.
        .toolbarBackground(Brand.surface, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .modifier(OverviewNotNowChrome(onNotNow: onNotNow))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                animatedProgress = viewModel.progress
            }
        }
        .task {
            let before = viewModel.progress
            await viewModel.refreshEmailVerified()
            // The seed may have ticked a row after the appear animation
            // started, so bring the bar up to the new progress.
            guard viewModel.progress != before else { return }
            withAnimation(.easeOut(duration: 0.4)) {
                animatedProgress = viewModel.progress
            }
        }
    }
}

// MARK: - Not now chrome

/// The hub's exit (D-01). With an exit the back chevron and the swipe-back
/// are removed, because a hub with neither would strand the user; without
/// one (previews) the screen keeps its system back button.
///
/// `BookingRequestSentPopGestureLock` is reused as is: it restores
/// swipe-back while a checklist step is pushed on top. "Not now" is a
/// secondary action, so it uses `Brand.onSurfaceVariant`, not the accent
/// (UI-SPEC A1).
private struct OverviewNotNowChrome: ViewModifier {
    let onNotNow: (() -> Void)?

    func body(content: Content) -> some View {
        if let onNotNow {
            content
                .navigationBarBackButtonHidden(true)
                .background(BookingRequestSentPopGestureLock())
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Not now") { onNotNow() }
                            .font(.brand(.body))
                            .foregroundStyle(Brand.onSurfaceVariant)
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Preview helpers

private func checklist(completedCount: Int) -> [ChecklistItem] {
    SignupOverviewViewModel.defaultChecklist.enumerated().map { index, item in
        ChecklistItem(kind: item.kind, title: item.title, isComplete: index < completedCount)
    }
}

private enum PreviewRoute: Hashable {
    case signupOverview
    case basicInfo
    case timezone
    case profilePhoto
    case verifyEmail
    case tags
    case review
}

/// Wraps the overview screen in a NavigationStack with a dummy "Create
/// account" parent already pushed, so the system back chevron renders in
/// the canvas and checklist taps still navigate to their destinations.
private struct PreviewOverview: View {
    let viewModel: SignupOverviewViewModel
    @State private var path: [PreviewRoute]

    init(viewModel: SignupOverviewViewModel) {
        self.viewModel = viewModel
        _path = State(initialValue: [.signupOverview])
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Text("Create account")
                NavigationLink("Complete your profile", value: PreviewRoute.signupOverview)
            }
            .navigationTitle("Signup")
            .navigationDestination(for: PreviewRoute.self) { route in
                switch route {
                case .signupOverview:
                    SignupOverviewView(
                        viewModel: viewModel,
                        onNext: { path.append(.review) },
                        onChecklistItemTap: { item in
                            switch item.kind {
                            case .basicInfo:      path.append(.basicInfo)
                            case .timezone:       path.append(.timezone)
                            case .profilePicture: path.append(.profilePhoto)
                            case .verifyEmail:    path.append(.verifyEmail)
                            case .expertise:      path.append(.tags)
                            }
                        }
                    )
                case .basicInfo:    SignupBasicInfoView()
                case .timezone:     SignupTimezoneView()
                case .profilePhoto: SignupProfilePhotoView()
                case .verifyEmail:  SignupVerifyEmailView()
                case .tags:         SignupTagsView()
                case .review:       SignupReviewView()
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Default (4 of 5)") {
    PreviewOverview(viewModel: SignupOverviewViewModel())
}

#Preview("0 of 5 — Nothing done") {
    PreviewOverview(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 0)
    ))
}

#Preview("2 of 5 — Identity done") {
    PreviewOverview(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 2)
    ))
}

#Preview("5 of 5 — All complete") {
    PreviewOverview(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 5)
    ))
}
