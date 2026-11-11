//
//  ToastCenter.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-10.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

/// The one shared transient confirmation (BOOK-06, D-03; UI-SPEC section 10).
///
/// Owned above the screens, at the client and expert shells (each applies a
/// `ToastHost`), so a message posted just before a pop is still shown after
/// it. The expert shell needs one because a dual-role user can answer a client
/// reschedule proposal from a chat row there.
///
/// Producers call `show` after the server answered 2xx and before they pop.
/// There is one toast at a time: a new message replaces the current one and
/// restarts the timer.
@MainActor
@Observable
final class ToastCenter {

    /// One message on screen. A fresh `id` per `show`, so a replaced toast is
    /// told apart from the one that replaced it.
    struct Toast: Equatable, Identifiable {
        let id: UUID
        let message: String
        let systemImage: String?
    }

    @MainActor static let shared = ToastCenter()

    /// The toast on screen, or `nil`.
    private(set) var current: Toast?

    @ObservationIgnored private let displayDuration: Duration
    @ObservationIgnored private var dismissTask: Task<Void, Never>?

    /// - Parameter displayDuration: How long a toast stays. UI-SPEC says 4 seconds;
    ///   tests inject a shorter or longer value.
    init(displayDuration: Duration = .seconds(4)) {
        self.displayDuration = displayDuration
    }

    /// Show `message`, replacing any toast on screen and restarting the timer.
    /// Also posts the text as a VoiceOver announcement, because the toast is
    /// not focusable in time.
    /// - Parameters:
    ///   - message: Fixed status copy from the UI-SPEC.
    ///   - systemImage: Optional SF Symbol shown before the text.
    func show(_ message: String, systemImage: String? = nil) {
        dismissTask?.cancel()
        let toast = Toast(id: UUID(), message: message, systemImage: systemImage)
        current = toast

        let duration = displayDuration
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard !Task.isCancelled else { return }
            // Only clear the toast this task was started for, so a replaced
            // toast never cuts the new one short.
            guard let self, self.current?.id == toast.id else { return }
            self.current = nil
        }

        AccessibilityNotification.Announcement(message).post()
    }

    /// Clear the toast now (tap to dismiss).
    func dismiss() {
        dismissTask?.cancel()
        dismissTask = nil
        current = nil
    }
}
