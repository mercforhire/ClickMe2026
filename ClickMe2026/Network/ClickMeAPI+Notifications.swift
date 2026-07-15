//
//  ClickMeAPI+Notifications.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-20.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

extension ClickMeAPI {

    func registerDeviceToken(
        deviceId: String,
        token: String,
        platform: String,
        appVersion: String? = nil
    ) async throws -> SuccessMessageResponse {
        var params: [String: Any] = [
            "device_id": deviceId,
            "token": token,
            "platform": platform
        ]
        if let appVersion { params["app_version"] = appVersion }
        return try await service.httpRequest(url: url(.registerDeviceToken), method: .post, parameters: params)
    }

    func unregisterDeviceToken(deviceId: String) async throws -> SuccessMessageResponse {
        try await service.httpRequest(
            url: url(.unregisterDeviceToken, deviceId: deviceId),
            method: .delete
        )
    }

    func getNotifications(
        category: String? = nil,
        unreadOnly: Bool = false,
        page: Int = 1,
        limit: Int = 20
    ) async throws -> SuccessDataResponse<NotificationsPayload> {
        var params: [String: Any] = ["unread_only": unreadOnly, "page": page, "limit": limit]
        if let category { params["category"] = category }
        return try await service.httpRequest(url: url(.getNotifications), method: .get, parameters: params)
    }

    func getNotificationPreferences() async throws -> SuccessDataResponse<NotificationPreferencesData> {
        try await service.httpRequest(url: url(.getNotificationPreferences), method: .get)
    }

    func updateNotificationPreferences(_ body: UpdateNotificationPreferencesRequest) async throws -> SuccessMessageResponse {
        try await service.httpRequest(url: url(.updateNotificationPreferences), method: .patch, body: body)
    }
}
