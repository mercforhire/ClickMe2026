//
//  CalendarEventEditorSheet.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import EventKit
import EventKitUI
import SwiftUI

/// Presents Apple's system `EKEventEditViewController` pre-filled from a
/// `BookingConfirmation`. The user sees the native "New Event" sheet and
/// taps "Add" (or edits first) to write it into their default calendar.
///
/// Notes:
/// - Requires `NSCalendarsWriteOnlyAccessUsageDescription` in Info.plist
///   (iOS 17+). Older systems also accept `NSCalendarsUsageDescription`.
/// - `EKEventEditViewController` requests access itself on first use; we
///   don't need to pre-prompt.
struct CalendarEventEditorSheet: UIViewControllerRepresentable {
    let booking: BookingConfirmation
    let calendarPayload: BookingCalendarPayload
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let controller = EKEventEditViewController()
        controller.eventStore = store
        controller.editViewDelegate = context.coordinator
        controller.event = Self.makeEvent(
            booking: booking,
            calendarPayload: calendarPayload,
            in: store
        )
        return controller
    }

    func updateUIViewController(_ vc: EKEventEditViewController, context: Context) {}

    // MARK: - Event construction

    private static func makeEvent(
        booking: BookingConfirmation,
        calendarPayload: BookingCalendarPayload,
        in store: EKEventStore
    ) -> EKEvent {
        let event = EKEvent(eventStore: store)
        event.title = "ClickMe · \(booking.expertName)"
        event.startDate = calendarPayload.startDate
        event.endDate = calendarPayload.endDate
        event.notes = booking.meetingNote
        if !booking.isVirtual {
            event.location = booking.meetingNote
        }
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
