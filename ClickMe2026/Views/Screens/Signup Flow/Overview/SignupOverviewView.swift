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

    // UI-only animation state
    @State private var animatedProgress = 0.0

    init(
        viewModel: SignupOverviewViewModel = SignupOverviewViewModel(),
        onNext: @escaping () -> Void = {},
        onChecklistItemTap: @escaping (ChecklistItem) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
        self.onChecklistItemTap = onChecklistItemTap
    }

    /// Runtime init — the checklist tracks the accumulator's progress
    /// automatically as the user completes earlier steps.
    init(
        accumulator: SignupAccumulator,
        onNext: @escaping () -> Void = {},
        onChecklistItemTap: @escaping (ChecklistItem) -> Void = { _ in }
    ) {
        self.init(
            viewModel: SignupOverviewViewModel(accumulator: accumulator),
            onNext: onNext,
            onChecklistItemTap: onChecklistItemTap
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.15)) {
                animatedProgress = viewModel.progress
            }
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
