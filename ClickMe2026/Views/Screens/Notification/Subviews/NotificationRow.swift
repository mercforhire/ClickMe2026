//
//  NotificationRow.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// A single notification card. Renders the leading circular icon, title,
/// body (with `**bold**` inline highlights via Markdown), and timestamp.
/// Phase 17 dropped the unread-dot indicator — notifications now expire
/// on a per-category TTL instead of being read-tracked.
struct NotificationRow: View {
    let item: NotificationItem
    var now: Date = Date()

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            iconBadge

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold))
                    .kerning(0.28)
                    .foregroundColor(Brand.onSurface)

                bodyText
                    .font(.system(size: 14))
                    .foregroundColor(Brand.onSurfaceVariant)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(NotificationRow.timestampLabel(for: item.createdAt, now: now))
                    .font(.system(size: 12, weight: .medium))
                    .kerning(0.24)
                    .foregroundColor(Brand.onSurfaceVariant.opacity(0.60))
                    .padding(.top, 4)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Brand.surfaceContainerLow)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Brand.surfaceContainerHigh, lineWidth: 1)
                )
        )
    }

    // MARK: - Icon badge

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Brand.surfaceContainerHigh)
                .overlay(Circle().stroke(Brand.outlineVariant, lineWidth: 1))

            Image(systemName: iconName)
                .font(.system(size: 18, weight: iconIsPrimary ? .semibold : .regular))
                .foregroundColor(iconIsPrimary ? Brand.primary : Brand.onSurfaceVariant)
        }
        .frame(width: 48, height: 48)
    }

    /// SF Symbol matching each of the six Phase 17 categories.
    private var iconName: String {
        switch item.category {
        case .booking: return "calendar"
        case .session: return "timer"
        case .message: return "message.fill"
        case .review:  return "star.fill"
        case .payout:  return "banknote.fill"
        case .account: return "shield.fill"
        }
    }

    /// Which categories render with the primary neon tint (interactive/
    /// timely) versus the muted variant (informational/administrative).
    private var iconIsPrimary: Bool {
        switch item.category {
        case .booking, .session, .message, .review: return true
        case .payout, .account:                     return false
        }
    }

    // MARK: - Body text (with **bold** highlights)

    /// Renders the body via SwiftUI's Markdown initializer so `**bold**`
    /// spans in the server-provided string render as inline emphasis.
    /// Bold spans in the design also glow slightly green — we approximate
    /// by using `.primary` for emphasized runs when the notification is
    /// unread + interactive; on read items the emphasis stays neutral so
    /// it doesn't overpower.
    private var bodyText: Text {
        // `AttributedString(markdown:)` parses `**foo**` into a bold
        // run. We then walk the runs and tint the bold ones with the
        // primary accent, matching the design's green highlights.
        guard var attributed = try? AttributedString(markdown: item.body) else {
            return Text(item.body)
        }
        for run in attributed.runs {
            if let intent = run.inlinePresentationIntent, intent.contains(.stronglyEmphasized) {
                attributed[run.range].foregroundColor = Brand.primary
                attributed[run.range].font = .system(size: 14, weight: .semibold)
            }
        }
        return Text(attributed)
    }

    // MARK: - Timestamp

    /// "2 min ago" / "28 min ago" for today's items.
    /// "Yesterday, 4:20 PM" for yesterday.
    /// "Oct 12, 10:15 AM" for anything older.
    static func timestampLabel(for date: Date, now: Date) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfYesterday = calendar.date(byAdding: .day, value: -1, to: startOfToday) ?? startOfToday

        if date >= startOfToday {
            return relativeShort(from: date, to: now)
        }
        if date >= startOfYesterday {
            return "Yesterday, " + timeOnly.string(from: date)
        }
        return monthDayTime.string(from: date)
    }

    private static func relativeShort(from: Date, to: Date) -> String {
        let seconds = max(0, Int(to.timeIntervalSince(from)))
        if seconds < 60 {
            return "Just now"
        }
        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes) min ago"
        }
        let hours = minutes / 60
        return "\(hours) hr ago"
    }

    private static let timeOnly: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    private static let monthDayTime: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f
    }()
}

// MARK: - Preview

#if DEBUG
#Preview("Booking Request") {
    NotificationRow(item: NotificationItem(
        id: UUID(),
        userId: UUID(),
        category: .booking,
        title: "Booking Request",
        body: "**Sarah Chen** sent you a booking request for UI Design.",
        metaData: nil,
        expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 14),
        isExpertOnly: false,
        createdAt: Date().addingTimeInterval(-120)
    ))
    .padding(20)
    .background(Brand.surface)
    .preferredColorScheme(.dark)
}

#Preview("Session Reminder") {
    NotificationRow(item: NotificationItem(
        id: UUID(),
        userId: UUID(),
        category: .session,
        title: "Session Reminder",
        body: "Your session with **Marcus Chen** starts in 30 minutes.",
        metaData: nil,
        expiresAt: Date().addingTimeInterval(60 * 60 * 24),
        isExpertOnly: false,
        createdAt: Date().addingTimeInterval(-1_680)
    ))
    .padding(20)
    .background(Brand.surface)
    .preferredColorScheme(.dark)
}
#endif
