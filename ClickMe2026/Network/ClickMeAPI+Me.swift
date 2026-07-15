//
//  ClickMeAPI+Me.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func getMe() async throws -> SuccessDataResponse<MeData> {
        try await service.httpRequest(url: url(.getMe), method: .get)
    }
}
