//
//  PaymentMethodRow.swift
//  ClickMe2026
//
//  Copyright © 2026 Q42. All rights reserved.
//

import SwiftUI

/// Single saved-card row. Shows brand mark, "Visa ···· 4242", expiry,
/// a default badge when applicable, and a trailing `···` menu button
/// exposing "Set as Default" / "Remove" actions.
struct PaymentMethodRow: View {
    let paymentMethod: PaymentMethodItem
    let isBusy: Bool
    let onSetDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            brandIcon
            details
            Spacer(minLength: 8)
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(PaymentMethodsBrand.rowBg)
        )
    }

    private var brandIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(PaymentMethodsBrand.cardBg)
                .frame(width: 44, height: 30)
            Image(systemName: PaymentMethodBrandDisplay.systemImage(paymentMethod.brand))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(PaymentMethodsBrand.onSurface)
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Text("\(PaymentMethodBrandDisplay.name(paymentMethod.brand)) ···· \(paymentMethod.last4)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(PaymentMethodsBrand.onSurface)
                if paymentMethod.isDefault {
                    defaultBadge
                }
            }
            Text(expiryText)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
        }
    }

    private var defaultBadge: some View {
        Text("Default")
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundColor(PaymentMethodsBrand.onPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(PaymentMethodsBrand.brandGreen)
            )
    }

    @ViewBuilder
    private var trailing: some View {
        if isBusy {
            ProgressView()
                .controlSize(.small)
                .tint(PaymentMethodsBrand.onSurfaceVar)
        } else {
            Menu {
                if !paymentMethod.isDefault {
                    Button {
                        onSetDefault()
                    } label: {
                        Label("Set as Default", systemImage: "star")
                    }
                }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(PaymentMethodsBrand.onSurfaceVar)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
    }

    /// "Expires 09/28" — zero-pads the month and keeps the year as
    /// two digits per convention on physical cards.
    private var expiryText: String {
        let month = String(format: "%02d", paymentMethod.expMonth)
        let yy = String(paymentMethod.expYear).suffix(2)
        return "Expires \(month)/\(yy)"
    }
}
