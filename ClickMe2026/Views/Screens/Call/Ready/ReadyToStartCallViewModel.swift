//
//  ReadyToStartCallViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-07-01.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

@MainActor
final class ReadyToStartCallViewModel: ObservableObject {

    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    // MARK: Identity

    /// Booking id used to hit `POST /bookings/:id/join`. Nil in the
    /// preview / design path (VM populates canned copy without a network
    /// call).
    let bookingId: UUID?

    // MARK: Content
    @Published var skypeLink: String
    @Published var loadState: LoadState = .idle

    // MARK: Copy state
    @Published var didCopy: Bool

    // MARK: Entry animation state
    @Published var glowPulse: Bool
    @Published var iconScale: CGFloat
    @Published var iconOpacity: Double
    @Published var bodyOpacity: Double
    @Published var bodyOffset: CGFloat

    // MARK: Dependencies

    private let api: ClickMeAPI

    // MARK: - Runtime init

    /// Runtime init — fetches the Skype/Zoom link via
    /// `POST /bookings/:id/join`.
    init(
        bookingId: UUID,
        api: ClickMeAPI = .shared
    ) {
        self.bookingId = bookingId
        self.skypeLink = ""
        self.didCopy = false
        self.glowPulse = false
        self.iconScale = 0.80
        self.iconOpacity = 0
        self.bodyOpacity = 0
        self.bodyOffset = 18
        self.api = api
    }

    // MARK: - Preview / design init

    init(
        skypeLink: String = "https://join.skype.com/aBcDeFg12345",
        didCopy: Bool = false,
        glowPulse: Bool = false,
        iconScale: CGFloat = 0.80,
        iconOpacity: Double = 0,
        bodyOpacity: Double = 0,
        bodyOffset: CGFloat = 18
    ) {
        self.bookingId = nil
        self.skypeLink = skypeLink
        self.didCopy = didCopy
        self.glowPulse = glowPulse
        self.iconScale = iconScale
        self.iconOpacity = iconOpacity
        self.bodyOpacity = bodyOpacity
        self.bodyOffset = bodyOffset
        self.api = .shared
    }

    /// Preview seam — installs canned data as if the fetch had succeeded.
    static func previewSeed(
        skypeLink: String = "https://join.skype.com/aBcDeFg12345"
    ) -> ReadyToStartCallViewModel {
        let vm = ReadyToStartCallViewModel(skypeLink: skypeLink)
        vm.loadState = .loaded
        return vm
    }

    // MARK: - Load

    /// Idempotent — skips when already loaded.
    func load() async {
        if case .loaded = loadState { return }
        await forceLoad()
    }

    func reload() async {
        await forceLoad()
    }

    private func forceLoad() async {
        guard let bookingId else {
            // Preview path — nothing to fetch.
            loadState = .loaded
            return
        }
        loadState = .loading
        do {
            let response = try await api.joinCall(id: bookingId)
            switch response.data.connectionType {
            case .skypeZoom:
                guard let link = response.data.externalConfig?.joinUrl, !link.isEmpty else {
                    loadState = .failed("The meeting link isn't available yet. Please try again in a moment.")
                    return
                }
                skypeLink = link
                loadState = .loaded
            case .inAppVoice:
                // Wrong destination — this screen is only for external
                // meeting links. In-app voice is handled by AgoraManager
                // on the call screen.
                loadState = .failed("This booking uses in-app voice, not Skype/Zoom.")
            }
        } catch {
            loadState = .failed(Self.errorMessage(for: error))
        }
    }

    // MARK: - Actions

    /// Staggered entry animation: glow pulse → icon spring → headline/CTA slide-up.
    func runEntryAnimation() {
        glowPulse = true

        withAnimation(.spring(response: 0.55, dampingFraction: 0.65).delay(0.15)) {
            iconScale = 1.0
            iconOpacity = 1.0
        }
        withAnimation(.easeOut(duration: 0.45).delay(0.38)) {
            bodyOpacity = 1
            bodyOffset = 0
        }
    }

    /// Copy the Skype link to the pasteboard and briefly show a "Copied" state.
    func copyLink() {
        UIPasteboard.general.string = skypeLink
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { didCopy = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation { self?.didCopy = false }
        }
    }

    // MARK: - Error mapping

    private static func errorMessage(for error: Error) -> String {
        if case let NetworkError.httpError(_, data) = error,
           let response = try? JSONDecoder().decode(StandardErrorResponse.self, from: data)
        {
            return response.message
        }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }
}
