//
//  DeleteAccountWarningHeader.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-21.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI

// MARK: - "Are you sure..." warning headline + what deletion does

struct DeleteAccountWarningHeader: View {
    /// The upfront line and the three groups show on the confirmation step; the
    /// feedback step keeps the headline and the permanence line only, so the long
    /// copy is read once, before the user commits.
    var showsDetails = true

    var body: some View {
        // 16 pt (md) between the headline, the lines and each group (05-UI-SPEC).
        VStack(alignment: .leading, spacing: 16) {
            Text("Are you sure you want to\ndelete your account?")
                .font(.brand(.title, weight: .bold))
                .foregroundColor(DeleteAccountBrand.onSurface)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            bodyText(AccountDeletionCopy.permanence)

            if showsDetails {
                bodyText(AccountDeletionCopy.bookingsFirst)

                group(title: AccountDeletionCopy.deletedTitle, body: AccountDeletionCopy.deletedBody)
                group(title: AccountDeletionCopy.keptAnonymizedTitle, body: AccountDeletionCopy.keptAnonymizedBody)
                group(title: AccountDeletionCopy.keptTitle, body: AccountDeletionCopy.keptBody)
            }
        }
    }

    // MARK: Pieces

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.brand(.subheadline, weight: .regular))
            .foregroundColor(DeleteAccountBrand.onSurfaceVar)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// A bold title over its body, 4 pt (xs) apart.
    private func group(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.brand(.subheadline, weight: .bold))
                .foregroundColor(DeleteAccountBrand.onSurface)
                .fixedSize(horizontal: false, vertical: true)

            bodyText(body)
        }
    }
}

#Preview("Details") {
    ScrollView {
        DeleteAccountWarningHeader()
            .padding(20)
    }
    .background(DeleteAccountBrand.bg)
    .preferredColorScheme(.dark)
}

#Preview("Short") {
    DeleteAccountWarningHeader(showsDetails: false)
        .padding(20)
        .background(DeleteAccountBrand.bg)
        .preferredColorScheme(.dark)
}
