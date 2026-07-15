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

struct ChecklistItem: Identifiable {
    let id = UUID()
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

    // UI-only animation state
    @State private var animatedProgress = 0.0

    init(
        viewModel: SignupOverviewViewModel = SignupOverviewViewModel(),
        onNext: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNext = onNext
    }

    var body: some View {
        ZStack {
            OverviewTheme.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    OverviewHeader()

                    OverviewProgressBar(
                        progress: viewModel.progress,
                        animatedProgress: animatedProgress
                    )
                    .padding(.top, 28)

                    VStack(spacing: 14) {
                        ForEach(viewModel.checklist) { OverviewChecklistRow(item: $0) }
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
        ChecklistItem(title: item.title, isComplete: index < completedCount)
    }
}

// MARK: - Previews

#Preview("Default (3 of 4)") {
    SignupOverviewView()
}

#Preview("0 of 4 — Nothing done") {
    SignupOverviewView(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 0)
    ))
}

#Preview("1 of 4 — Picture added") {
    SignupOverviewView(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 1)
    ))
}

#Preview("2 of 4 — Email verified") {
    SignupOverviewView(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 2)
    ))
}

#Preview("3 of 4 — Rate set") {
    SignupOverviewView(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 3)
    ))
}

#Preview("4 of 4 — All complete") {
    SignupOverviewView(viewModel: SignupOverviewViewModel(
        checklist: checklist(completedCount: 4)
    ))
}
