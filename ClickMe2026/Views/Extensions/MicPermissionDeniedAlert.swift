//
//  MicPermissionDeniedAlert.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import SwiftUI
import UIKit

// MARK: - Mic-permission-denied alert
//
// A reusable `.alert` modifier for the "user tried to join a call but
// the microphone permission is denied" case. ClickMe's voice-call core
// is non-functional without the mic, so Dismiss-only isn't enough —
// this alert surfaces an **Open Settings** button that deep-links to
// `UIApplication.openSettingsURLString`, landing the user directly on
// the ClickMe permissions page in iOS Settings.
//
// Usage:
// ```swift
// .micPermissionDeniedAlert(isPresented: $callCenter.micPermissionDenied)
// ```

private struct MicPermissionDeniedAlertModifier: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.alert(
            "Microphone access needed",
            isPresented: $isPresented
        ) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                isPresented = false
            }
            Button("Cancel", role: .cancel) {
                isPresented = false
            }
        } message: {
            Text("ClickMe needs microphone access to join voice sessions. Tap Open Settings → Microphone to enable it.")
        }
    }
}

extension View {
    /// Shows the mic-permission-denied alert when `isPresented` flips
    /// true. Offers an **Open Settings** deep-link so the user can
    /// re-grant the permission without hunting through iOS Settings.
    func micPermissionDeniedAlert(isPresented: Binding<Bool>) -> some View {
        modifier(MicPermissionDeniedAlertModifier(isPresented: isPresented))
    }
}
