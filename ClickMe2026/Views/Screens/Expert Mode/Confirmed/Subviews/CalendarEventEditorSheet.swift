//
//  CalendarEventEditorSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import EventKit
import EventKitUI
import SwiftUI

/// Presents Apple's system `EKEventEditViewController` pre-filled from a plain
/// `BookingCalendarPayload` (title, notes, start, end), so Booking Confirmed
/// and the summary screens share one sheet (EXP-10, D-13,
/// G-06-1-summary-calendar). Booking Confirmed's event is titled
/// `ClickMe · {topic} with {client name}` with the meeting type and the
/// client's message as notes, and has no location. The user sees the native
/// "New Event" sheet and taps "Add" (or edits first) to write it into their
/// default calendar.
///
/// Notes:
/// - Requires `NSCalendarsWriteOnlyAccessUsageDescription` in Info.plist
///   (iOS 17+). Older systems also accept `NSCalendarsUsageDescription`.
/// - `EKEventEditViewController` requests access itself on first use; we
///   don't need to pre-prompt.
struct CalendarEventEditorSheet: UIViewControllerRepresentable {
    let event: BookingCalendarPayload
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        controller.event = Self.makeEvent(event, in: store)
        return controller
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}

    // MARK: - Event construction

    static func makeEvent(_ event: BookingCalendarPayload, in store: EKEventStore) -> EKEvent {
        let ekEvent = EKEvent(eventStore: store)
        ekEvent.title = event.title
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.notes = event.notes
        // 15-minute reminder mirrors the "starting now" window used
        // elsewhere in the app.
        ekEvent.addAlarm(EKAlarm(relativeOffset: -15 * 60))
        return ekEvent
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, EKEventEditViewDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func eventEditViewController(
            _ controller: EKEventEditViewController,
            didCompleteWith action: EKEventEditViewAction
        ) {
            controller.dismiss(animated: true) { [onDismiss] in
                onDismiss()
            }
        }
    }
}
