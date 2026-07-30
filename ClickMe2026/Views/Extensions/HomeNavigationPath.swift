//
//  HomeNavigationPath.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Shared `NavigationPath` holder injected into every child of a
/// `HomeClientView` / `HomeExpertView`. Exists so tabs (Explore, Search,
/// My Bookings, …) can push destinations onto their host shell's
/// single `NavigationStack` instead of wrapping each tab in its own
/// stack.
///
/// Why not a plain `Binding<NavigationPath>`? Env values must be
/// `Sendable` non-optional constants; an `ObservableObject` reference
/// works cleanly with `@Environment(\.homeNavigationPath)` and lets
/// tabs push via `navPath.push(route)` without threading bindings
/// through every intermediate view.
@MainActor
final class HomeNavigationPath: ObservableObject {

    @Published var path: NavigationPath

    init(_ path: NavigationPath = NavigationPath()) {
        self.path = path
    }

    /// Push a Hashable destination onto the shell's shared stack.
    func push<V: Hashable>(_ value: V) {
        path.append(value)
    }

    /// Pop the most-recent destination. No-op if the stack is at root.
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Return to the tab root — used on tab switches so a user who
    /// navigated deep in one tab doesn't see that stack when they
    /// switch to another.
    func reset() {
        path = NavigationPath()
    }
}

extension EnvironmentValues {
    /// The active shell's shared nav path. `nil` when a view is
    /// rendered outside a `HomeClientView` / `HomeExpertView` (e.g.
    /// SwiftUI previews) — callers should fall back to a local `@State`
    /// path in that case.
    @Entry var homeNavigationPath: HomeNavigationPath? = nil
}

// MARK: - Shell-level routes

/// Destinations reachable from the shell chrome (top bar / tab bar
/// widgets) rather than from a specific tab. Currently only the bell
/// icon → notifications list — add more here if the top bar ever
/// grows other push actions.
enum HomeRoute: Hashable {
    case notifications
    /// Reached via the top-bar avatar tap. Renders `ModeSwitchView` so
    /// switching between client / expert home is a 1-tap shortcut
    /// (rather than 3 taps via Profile → Switch mode card → confirm).
    case modeSwitch
    /// A chat thread pushed via `openChatThread(...)` — e.g. from tapping
    /// "Message" on an expert profile. Carries the seed the ChatView
    /// needs (thread id + peer identity) so the destination handler
    /// doesn't have to re-fetch just to render the header.
    case chat(threadId: UUID, peerName: String, peerAvatarURL: String)
    /// Pushed from a tapped system-event row inside a chat when the
    /// underlying booking is still in-flight (request / confirmed /
    /// rescheduled). Renders `UpcomingBookingView(bookingId:)`.
    case upcomingBooking(bookingId: UUID)
    /// Pushed from a tapped system-event row when the booking is in a
    /// terminal state (declined / cancelled / completed / expired) —
    /// renders `BookingSummaryView(bookingId:)` in read-only mode.
    case bookingSummary(bookingId: UUID)
    /// Expert-side counterpart to `bookingSummary`. Pushed from the
    /// expert's upcoming-session card tap and renders
    /// `ExpertBookingSummaryView(bookingId:)` (data source is
    /// `/expert/bookings/:id/details`, not the client-facing endpoint).
    case expertBookingSummary(bookingId: UUID)
    /// Expert-side reschedule flow. Pushed from
    /// `ExpertBookingSummaryView`'s Reschedule action; renders
    /// `ExpertRescheduleView(bookingId:)` and posts to
    /// `PATCH /expert/bookings/:id/reschedule` on submit.
    case expertReschedule(bookingId: UUID)
    /// Pushed from the chat menu's "View Profile" tap. Each shell renders
    /// the perspective-appropriate view — client shell → `ExpertProfileView`,
    /// expert shell → `ClientProfileView`. `name` and `avatarURL` are seed
    /// values so the header renders instantly; the destination view then
    /// fetches the rest.
    case peerProfile(userId: UUID, name: String, avatarURL: String)
}

// MARK: - Shell action: open a chat thread

/// Env-injected closure the shell provides so leaf screens (e.g.
/// `ExpertProfileView`) can tell the shell "switch to the Chats tab and
/// push this thread." Both shells (client + expert) install it; the
/// implementation is responsible for switching `selectedTab` first, then
/// pushing `HomeRoute.chat(...)` on the shared nav path *after* the
/// tab-switch's automatic path-reset has run.
struct OpenChatThreadAction {
    /// (threadId, peerName, peerAvatarURL)
    let action: (UUID, String, String) -> Void
    func callAsFunction(threadId: UUID, peerName: String, peerAvatarURL: String) {
        action(threadId, peerName, peerAvatarURL)
    }
}

extension EnvironmentValues {
    /// Provided by `HomeClientView` / `HomeExpertView`. `nil` when a view
    /// is rendered outside a shell (previews, tests); callers should
    /// short-circuit gracefully in that case.
    @Entry var openChatThread: OpenChatThreadAction? = nil
}
