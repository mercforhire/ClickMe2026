//
//  PushRouter.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Where a tapped push notification should land in the app. Named
/// route enum rather than raw view identifiers so the shell views
/// (`HomeClientView` / `HomeExpertView`) can pattern-match without
/// knowing the payload shape.
enum PushDestination: Equatable {
    /// Booking detail — used by `booking/*` events on confirmed
    /// bookings and most `session/*` events. The current mode's
    /// booking-summary view is opened.
    case bookingDetail(bookingId: UUID)
    /// Expert's pending booking requests hub. Used by
    /// `booking/requests` (documented spec) or `event_type` values
    /// matching `NEW_BOOKING_REQUEST`. Client shells fall back to the
    /// notifications list — clients don't have this screen.
    case incomingRequests
    /// A single pending booking request, expert only — used by
    /// `booking/requests` when the payload carries a booking id. The request
    /// id is the bookings row id, so the shell opens that request's decision
    /// screen. The client shell falls back to the notifications list.
    case incomingRequest(bookingId: UUID)
    /// A booking in a terminal state (declined, cancelled, expired or
    /// refunded) — used by `booking/declines`, `booking/cancellations`,
    /// `booking/expirations` and `booking/refunds`. Opens the booking
    /// summary, not the upcoming-booking screen.
    case bookingSummary(bookingId: UUID)
    /// Chat thread — used by `message/new_message`. The shell switches
    /// to the Chats tab first, then pushes the thread.
    case chatThread(threadId: UUID)
    /// Leave-review flow — used by `review/nudge` and `session/ended`.
    /// Opens the summary; the summary's own Leave-Review CTA takes it
    /// from there.
    case leaveReview(bookingId: UUID)
    /// Payouts / earnings screen — used by `payout/paid`, `payout/failed`.
    case payouts
    /// Stripe Connect KYC flow — `payout/kyc_action`. Payload has no
    /// entity ID, so the shell just opens the Profile tab and the
    /// dashboard's onboarding banner does the rest.
    case kycOnboarding
    /// Security settings — `account/password_changed`. Deep-links into
    /// the client / expert profile hub → Security row.
    case accountSecurity
    /// Notifications hub — fallback for unrouted categories. Opens the
    /// in-app notifications list.
    case notificationsList
}

/// Global coordinator that translates a `PushEvent` (payload) into a
/// `PushDestination` (client concept) and hands it off to whichever
/// shell is currently on screen.
///
/// Why a router instead of routing directly from AppDelegate: the
/// shells own tab state (`selectedTab`) and their per-tab
/// `HomeNavigationPath`s. AppDelegate has neither. The router exposes a
/// published `pendingDestination`; the shells observe it, act, and
/// clear it. Keeps the coupling one-way + easy to unit-test.
///
/// Foreground-list refresh is a separate signal — `newNotificationTick`
/// — that `NotificationsListView` observes to trigger a silent reload
/// when a push arrives while the screen is on top.
@MainActor
final class PushRouter: ObservableObject {

    static let shared = PushRouter()

    /// Non-nil when a tapped push is waiting to be routed. The active
    /// shell clears this after handling. Never latched — a second push
    /// during the same session overwrites, matching how iOS delivers
    /// only the most-recently-tapped notification.
    @Published var pendingDestination: PushDestination?

    /// Bumps every time a push arrives in the foreground so
    /// `NotificationsListView` can `.onReceive` and silently reload.
    /// Value itself is meaningless; the change is the signal.
    @Published var newNotificationTick: Int = 0

    private init() {}

    // MARK: - Entry points from AppDelegate

    /// Called from `didReceive` (user tapped a notification, foreground
    /// or background). Parses the payload, computes a destination, and
    /// stores it for the shell to consume.
    func handleTap(_ event: PushEvent) {
        // An unknown or missing category opens the notifications list so
        // the user can at least see what came in (PUSH-01).
        pendingDestination = Self.destination(for: event) ?? .notificationsList
    }

    /// Called from `willPresent` (push arrived while app was in the
    /// foreground and not tapped). Bumps the refresh tick so the in-app
    /// list catches up, but does NOT set a destination — the user
    /// didn't ask to navigate.
    func handleForegroundArrival(_ event: PushEvent) {
        newNotificationTick &+= 1
    }

    // MARK: - Category → destination mapping

    /// Maps a `PushEvent` to a destination through the shared table.
    static func destination(for event: PushEvent) -> PushDestination? {
        destination(
            category: event.category,
            subCategory: event.subCategory,
            bookingId: event.bookingId,
            threadId: event.threadId
        )
    }

    /// The one category-to-destination table, shared by push taps and
    /// notifications-list rows so both land on the same screen. Contract:
    /// backend `docs/ios/PUSH-ROUTING.md`. Both strings are trimmed and
    /// lowercased first; an empty, missing or unknown category returns `nil`
    /// and the caller opens the notifications list.
    ///
    /// | category / sub_category                              | destination        |
    /// |------------------------------------------------------|--------------------|
    /// | booking/requests, with a booking id                  | incomingRequest    |
    /// | booking/requests, no booking id                      | incomingRequests   |
    /// | booking/declines, cancellations, expirations, refunds| bookingSummary     |
    /// | booking/payment_actions (route only, D-01)           | bookingDetail      |
    /// | booking/confirmations, reschedules, anything else    | bookingDetail      |
    /// | session/reminder, session/no_show                    | bookingDetail      |
    /// | session/ended                                        | leaveReview        |
    /// | message/new_message                                  | chatThread         |
    /// | review/received                                      | bookingDetail      |
    /// | review/nudge                                         | leaveReview        |
    /// | payout/paid, payout/failed, payout/dispute           | payouts            |
    /// | payout/kyc_action                                    | kycOnboarding      |
    /// | account/password_changed, account/deletion_requested | accountSecurity    |
    /// | (anything else)                                      | nil                |
    ///
    /// A row that needs an id (booking detail, summary, review, chat) returns
    /// `nil` when the id is missing.
    static func destination(
        category: String?,
        subCategory: String?,
        bookingId: UUID?,
        threadId: UUID?
    ) -> PushDestination? {
        let category = category?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let subCategory = subCategory?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        switch category {
        case "booking":
            // `booking/requests` is a pending expert-decision request — no
            // confirmed booking yet. With an id it opens that request; without
            // one, the requests hub.
            if subCategory == "requests" {
                if let bookingId { return .incomingRequest(bookingId: bookingId) }
                return .incomingRequests
            }
            guard let bookingId else { return nil }
            switch subCategory {
            case "declines", "cancellations", "expirations", "refunds":
                return .bookingSummary(bookingId: bookingId)
            default:
                return .bookingDetail(bookingId: bookingId)
            }

        case "session":
            guard let bookingId else { return nil }
            if subCategory == "ended" {
                // Server flags a completed session as a review prompt.
                return .leaveReview(bookingId: bookingId)
            }
            return .bookingDetail(bookingId: bookingId)

        case "message":
            guard let threadId else { return nil }
            return .chatThread(threadId: threadId)

        case "review":
            guard let bookingId else { return nil }
            if subCategory == "nudge" {
                return .leaveReview(bookingId: bookingId)
            }
            return .bookingDetail(bookingId: bookingId)

        case "payout":
            if subCategory == "kyc_action" {
                return .kycOnboarding
            }
            return .payouts

        case "account":
            return .accountSecurity

        default:
            return nil
        }
    }
}
