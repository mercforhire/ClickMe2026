//
//  ConnectionType.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Call connection discriminator. Used in `JoinCallResponse` to indicate whether
/// `agoraConfig` (in-app voice) or `externalConfig` (skype/zoom) is populated.
enum ConnectionType: String, Decodable {
    case inAppVoice = "in_app_voice"
    case skypeZoom  = "skype_zoom"
}
