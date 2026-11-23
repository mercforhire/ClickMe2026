//
//  RescheduleDeclineResponse.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-22.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import Foundation

/// Success envelope of `POST /client/bookings/{id}/decline-reschedule`
/// (`openapi/clickme-api.yaml`): `{ status, message, data: { booking_id, status } }`.
///
/// `data.status` is the status the server restored (`reschedule_prev_status`, or
/// `confirmed` for pre-migration rows), or the booking's current status on the
/// idempotent 200. Android reads the same field (`RescheduleResponseData`).
///
/// The decode is tolerant on purpose: a missing `data`, `data: null`, or a
/// `status` that is absent, null or not a string each leave `data` / `status`
/// nil. A declined proposal must never turn into a decode error because of an
/// unexpected body, since the user would then retry a decline the server has
/// already applied.
struct RescheduleDeclineResponse: Decodable {

    /// The part of `data` this build reads. `booking_id` is left out because
    /// nothing uses it and a malformed value must never fail the decode.
    struct RescheduleResponseData: Decodable {
        let status: String?

        private enum CodingKeys: String, CodingKey { case status }

        init(from decoder: Decoder) throws {
            let container = try? decoder.container(keyedBy: CodingKeys.self)
            status = try? container?.decodeIfPresent(String.self, forKey: .status)
        }
    }

    let status: String
    let message: String?
    let data: RescheduleResponseData?

    private enum CodingKeys: String, CodingKey { case status, message, data }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decodeIfPresent(String.self, forKey: .status)) ?? ""
        message = try? container.decodeIfPresent(String.self, forKey: .message)
        data = try? container.decodeIfPresent(RescheduleResponseData.self, forKey: .data)
    }

    /// The restored booking status, trimmed, or `nil` when the body carried none
    /// or only whitespace. Owners leave their status alone on `nil`.
    var restoredStatus: String? {
        guard let raw = data?.status?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else {
            return nil
        }
        return raw
    }
}
