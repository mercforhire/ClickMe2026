//
//  AgoraConnectionMappingTests.swift
//  ClickMe2026Tests
//
//  Pins how Agora's local connection states map onto the call screen
//  (CALL-05). Only a terminal `failed` may end the call; `disconnected` is the
//  initial state and the state after `leaveChannel`, so mapping it would report
//  a user's own hang-up as a dropped call.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Agora connection mapping")
struct AgoraConnectionMappingTests {

    @Test("raw values mirror Agora 4.6.2 AgoraConnectionState")
    func rawValues() {
        #expect(AgoraLinkState(rawValue: 1) == .disconnected)
        #expect(AgoraLinkState(rawValue: 2) == .connecting)
        #expect(AgoraLinkState(rawValue: 3) == .connected)
        #expect(AgoraLinkState(rawValue: 4) == .reconnecting)
        #expect(AgoraLinkState(rawValue: 5) == .failed)
    }

    @Test("unknown raw value is nil")
    func unknownRawValue() {
        #expect(AgoraLinkState(rawValue: 99) == nil)
        #expect(AgoraLinkState(rawValue: 0) == nil)
    }

    @Test("failed ends the local side")
    func failedDisconnects() {
        #expect(ConnectionState.localState(for: .failed) == .disconnected)
    }

    @Test("connected marks the local side ready")
    func connectedIsReady() {
        #expect(ConnectionState.localState(for: .connected) == .ready)
    }

    @Test("disconnected, connecting, reconnecting and nil change nothing")
    func otherStatesAreNoChange() {
        #expect(ConnectionState.localState(for: .disconnected) == nil)
        #expect(ConnectionState.localState(for: .connecting) == nil)
        #expect(ConnectionState.localState(for: .reconnecting) == nil)
        #expect(ConnectionState.localState(for: nil) == nil)
    }
}
