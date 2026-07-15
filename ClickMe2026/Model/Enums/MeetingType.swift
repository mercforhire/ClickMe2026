//
//  MeetingType.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

/// Meeting type discriminator used across booking responses.
enum MeetingType: String, Decodable {
    case inAppVoice = "in_app_voice"
    case skypeZoom  = "skype_zoom"
}
