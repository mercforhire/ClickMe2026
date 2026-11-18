//
//  ChatThreadItemDecodingTests.swift
//  ClickMe2026Tests
//
//  CHAT-03 (D-08): `blocked_by_me` decodes as false when the key is missing or null, so a
//  legacy block or a pre-rollout payload reads as blocked by the peer and offers no Unblock
//  (docs/ios/CHAT-UNBLOCK.md section 9). Every other thread field still decodes.
//  Pure: a JSONDecoder with `.convertFromSnakeCase`, null dates, no network stub.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("ChatThreadItem decoding")
@MainActor
struct ChatThreadItemDecodingTests {

    nonisolated private static let threadId = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"
    nonisolated private static let partnerId = "cccccccc-cccc-4ccc-8ccc-cccccccccccc"

    /// One `GET /chats` thread row. `blockedByMe` is written verbatim, or left out when nil.
    private static func json(isBlocked: Bool = false, blockedByMe: String? = nil) -> Data {
        let blockedByMeJSON = blockedByMe.map { #","blocked_by_me":\#($0)"# } ?? ""
        return Data(
            #"""
            {"thread_id":"\#(threadId)","partner_id":"\#(partnerId)","partner":{"id":"\#(partnerId)","name":"Dr. Test","avatar_url":null,"roles":["expert","client"]},"last_message":null,"last_msg_at":null,"unread_count":3,"is_online":true,"is_blocked":\#(isBlocked)\#(blockedByMeJSON)}
            """#.utf8
        )
    }

    private static func decode(_ data: Data) throws -> ChatThreadItem {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(ChatThreadItem.self, from: data)
    }

    @Test("a thread without the blocked_by_me key decodes with blockedByMe false")
    func missingKeyIsFalse() throws {
        let item = try Self.decode(Self.json(isBlocked: true))
        #expect(item.blockedByMe == false)
        #expect(item.isBlocked == true)
    }

    @Test("blocked_by_me null decodes as false")
    func nullIsFalse() throws {
        let item = try Self.decode(Self.json(isBlocked: true, blockedByMe: "null"))
        #expect(item.blockedByMe == false)
    }

    @Test("blocked_by_me true decodes as true and false as false")
    func explicitValuesKept() throws {
        #expect(try Self.decode(Self.json(isBlocked: true, blockedByMe: "true")).blockedByMe == true)
        #expect(try Self.decode(Self.json(isBlocked: true, blockedByMe: "false")).blockedByMe == false)
    }

    @Test("every other field still decodes")
    func otherFieldsDecode() throws {
        let item = try Self.decode(Self.json(isBlocked: true, blockedByMe: "true"))
        #expect(item.threadId == UUID(uuidString: Self.threadId))
        #expect(item.partner.id == UUID(uuidString: Self.partnerId))
        #expect(item.partner.name == "Dr. Test")
        #expect(item.partner.avatarUrl == nil)
        #expect(item.partner.roles == [.expert, .client])
        #expect(item.lastMessage == nil)
        #expect(item.lastMsgAt == nil)
        #expect(item.unreadCount == 3)
        #expect(item.isOnline == true)
        #expect(item.isBlocked == true)
    }

    @Test("a legacy block reads as blocked by the peer with no Unblock")
    func legacyBlockShowsNoUnblock() throws {
        let item = try Self.decode(Self.json(isBlocked: true))
        let state = ChatBlockState(
            isBlocked: ChatBlockState.ScannedBlock(thread: item).isBlocked,
            blockedByMe: ChatBlockState.ScannedBlock(thread: item).blockedByMe
        )
        #expect(state.showsUnblock == false)
        #expect(state.ownComposerMode == .blockedByPeer)
    }
}
