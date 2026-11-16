//
//  CalendarEventEditorSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import EventKit
import EventKitUI
import SwiftUI

/// Presents Apple's system `EKEventEditViewController` pre-filled from a
/// `BookingConfirmation`: the title `ClickMe · {topic} with {client name}`,
/// the booking's start and end, notes holding the meeting type and the
/// client's message, and no location (EXP-10, D-13). The user sees the native "New Event" sheet and
/// taps "Add" (or edits first) to write it into their default calendar.
///
/// Notes:
/// - Requires `NSCalendarsWriteOnlyAccessUsageDescription` in Info.plist
///   (iOS 17+). Older systems also accept `NSCalendarsUsageDescription`.
/// - `EKEventEditViewController` requests access itself on first use; we
///   don't need to pre-prompt.
struct CalendarEventEditorSheet: UIViewControllerRepresentable {
    let booking: BookingConfirmation
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        controller.event = Self.makeEvent(booking: booking, in: store)
        return controller
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}

    // MARK: - Event construction

    static func makeEvent(booking: BookingConfirmation, in store: EKEventStore) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = booking.calendarTitle
        event.startDate = booking.calendarPayload.startDate
        event.endDate = booking.calendarPayload.endDate
        event.notes = booking.calendarNotes
        // 15-minute reminder mirrors the "starting now" window used
        // elsewhere in the app.
        event.addAlarm(EKAlarm(relativeOffset: -15 * 60))
        return event
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
