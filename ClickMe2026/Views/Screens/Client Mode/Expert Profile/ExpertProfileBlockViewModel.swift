//
//  ExpertProfileBlockViewModel.swift
//  ClickMe2026
//
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Blocks an expert from their public profile (CHAT-04, D-06). RED stub: no behavior yet.
@MainActor
final class ExpertProfileBlockViewModel: ObservableObject {

    @Published private(set) var isBlocking = false
    @Published var apiError: String?

    private(set) var blockTask: Task<Void, Never>?

    init(api: ClickMeAPI = .shared, toasts: ToastCenter = .shared) {}

    static func displayName(_ name: String) -> String { name }

    func awaitBlock() async {}

    func block(peerId: UUID, peerName: String) {}
}
