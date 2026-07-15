//
//  JoinCallResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Call join context.
///
/// PITFALL 2 (dual-shape): both `agoraConfig` and `externalConfig` are always
/// present, but exactly one is non-nil. Use `connectionType` as the discriminator:
/// - `.inAppVoice` → `agoraConfig` populated, `externalConfig` nil
/// - `.skypeZoom`  → `externalConfig` populated, `agoraConfig` nil
struct JoinCallResponse: Decodable {
    struct AgoraConfig: Decodable {
        let rtcToken: String
        let uid: Int
        let channelName: String
    }

    struct ExternalConfig: Decodable {
        let joinUrl: String?
        let message: String?
    }

    let bookingId: UUID
    let connectionType: ConnectionType
    let agoraConfig: AgoraConfig?
    let externalConfig: ExternalConfig?
}
