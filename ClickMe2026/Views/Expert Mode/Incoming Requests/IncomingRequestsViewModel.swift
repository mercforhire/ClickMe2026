//
//  IncomingRequestsViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-05-18.
//  Copyright © 2026 Q42. All rights reserved.
//

import Observation
import SwiftUI

@Observable
final class IncomingRequestsViewModel {
    // MARK: Data

    var requests: [BookingRequest]

    // MARK: Actions

    var onRequestTap: (BookingRequest) -> Void

    // MARK: Init

    init(
        requests: [BookingRequest] = BookingRequest.samples,
        onRequestTap: @escaping (BookingRequest) -> Void = { _ in }
    ) {
        self.requests = requests
        self.onRequestTap = onRequestTap
    }
}
