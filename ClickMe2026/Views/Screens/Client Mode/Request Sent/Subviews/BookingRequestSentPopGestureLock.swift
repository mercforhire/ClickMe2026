//
//  BookingRequestSentPopGestureLock.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Swipe-back lock

/// Disables the interactive swipe-back while Request Sent is visible (D-05).
///
/// The booking already exists once Request Sent opens, so going back would
/// reopen the form and let the client submit the request again. Hiding the
/// back button alone is not assumed to stop the swipe (UI-SPEC section 3), and
/// iOS 26 adds a second recognizer, `interactiveContentPopGestureRecognizer`,
/// that pops from anywhere in the content area. Both are switched off in
/// `viewDidAppear` and put back to their previous state in `viewWillDisappear`,
/// so swipe-back keeps working on every other screen.
///
/// Attach it with `.background(BookingRequestSentPopGestureLock())`. It draws
/// nothing and takes no touches.
struct BookingRequestSentPopGestureLock: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> LockController {
        LockController()
    }

    func updateUIViewController(_ uiViewController: LockController, context: Context) {}

    final class LockController: UIViewController {
        private var previousEdgeEnabled: Bool?
        private var previousContentEnabled: Bool?

        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard previousEdgeEnabled == nil, let nav = navigationController else { return }

            previousEdgeEnabled = nav.interactivePopGestureRecognizer?.isEnabled
            nav.interactivePopGestureRecognizer?.isEnabled = false

            if #available(iOS 26, *) {
                previousContentEnabled = nav.interactiveContentPopGestureRecognizer?.isEnabled
                nav.interactiveContentPopGestureRecognizer?.isEnabled = false
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restore()
        }

        private func restore() {
            guard let nav = navigationController else {
                previousEdgeEnabled = nil
                previousContentEnabled = nil
                return
            }
            if let previousEdgeEnabled {
                nav.interactivePopGestureRecognizer?.isEnabled = previousEdgeEnabled
            }
            if #available(iOS 26, *), let previousContentEnabled {
                nav.interactiveContentPopGestureRecognizer?.isEnabled = previousContentEnabled
            }
            previousEdgeEnabled = nil
            previousContentEnabled = nil
        }
    }
}
