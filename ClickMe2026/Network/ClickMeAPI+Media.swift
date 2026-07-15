//
//  ClickMeAPI+Media.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func uploadMedia(fileData: Data, filename: String, mimeType: String) async throws -> SuccessDataResponse<MediaUploadData> {
        try await service.multipartUpload(
            url: url(.uploadMedia),
            parts: [.file(name: "file", filename: filename, mimeType: mimeType, data: fileData)]
        )
    }
}
