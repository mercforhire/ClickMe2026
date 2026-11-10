//
//  AgoraManager.swift
//  ClickMe2026
//
//  Created by Max Cobb on 03/04/2023.
//  Rewritten 2026-06-20 for Agora RTC SDK 4.x.
//

import AgoraRtcKit
import AVFoundation
import SwiftUI

// MARK: - UI state enums

enum ConnectionState {
    case waiting
    case ready
    case disconnected
}

/// The local connection states Agora reports through
/// `rtcEngine(_:connectionChangedTo:reason:)`.
///
/// Raw values mirror Agora 4.6.2 `AgoraConnectionState` so the mapping below
/// can be unit tested without linking the SDK.
nonisolated enum AgoraLinkState: Int {
    case disconnected = 1
    case connecting   = 2
    case connected    = 3
    case reconnecting = 4
    case failed       = 5
}

extension ConnectionState {
    /// The local `ConnectionState` an Agora link state should produce, or
    /// `nil` when the link state must not change what the call screen shows.
    ///
    /// Only `.failed` ends the call: the SDK has stopped trying to rejoin.
    /// `.disconnected` maps to `nil` on purpose. It is the state before the
    /// first join and the state after `leaveChannel`, so mapping it would end
    /// a call that is still starting, or report the user's own hang-up as a
    /// dropped call. `.connecting` and `.reconnecting` are transient and the
    /// SDK recovers from them on its own.
    nonisolated static func localState(for link: AgoraLinkState?) -> ConnectionState? {
        switch link {
        case .failed:    return .disconnected
        case .connected: return .ready
        default:         return nil
        }
    }
}

enum SpeakerState {
    case muted
    case ear
    case speaker

    func iconName() -> String {
        switch self {
        case .muted:   return "speaker.slash.fill"
        case .ear:     return "ear"
        case .speaker: return "speaker.wave.3.fill"
        }
    }
}

enum MicState {
    case muted
    case speaking

    func iconName() -> String {
        switch self {
        case .muted:    return "mic.slash.fill"
        case .speaking: return "mic.fill"
        }
    }
}

// MARK: - AgoraManager

@MainActor
final class AgoraManager: NSObject, ObservableObject {

    // MARK: Published state
    @Published var isPresentingCallScreen = false
    @Published var inInACall = false
    @Published var myConnectionState: ConnectionState = .waiting
    @Published var remoteConnectionState: ConnectionState = .waiting
    @Published var mySpeakerState: SpeakerState?
    @Published var myMicState: MicState?
    @Published var remoteMicState: MicState?
    @Published var agoraError: String?
    @Published var initializing = false
    @Published var joiningChannel = false

    // MARK: Internal state
    private var agoraKit: AgoraRtcEngineKit?
    private var currentChannel: String?
    private var currentToken: String?

    // MARK: - Permissions

    static func checkForPermissions() async -> Bool {
        await requestAuthorization(for: .audio)
    }

    private static func requestAuthorization(for mediaType: AVMediaType) async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .denied, .restricted: return false
        case .authorized:          return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }

    // MARK: - Engine lifecycle

    /// Initializes the Agora engine. No-op if already initialized.
    func initializeAgora(appId: String) {
        guard agoraKit == nil else { return }

        initializing = true

        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.channelProfile = .communication

        let engine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)

        // Surface the SDK's own logging to Xcode's console in DEBUG only.
        // Without this the Agora SDK is completely silent when a join
        // fails, which makes "no audio, no errors" bugs hard to
        // diagnose. `.info` level is chatty but bounded; drop to `.warn`
        // if it becomes noisy.
        #if DEBUG
        engine.setLogFilter(AgoraLogFilter.info.rawValue)
        #endif

        // Voice-only configuration
        engine.disableVideo()
        engine.setAudioProfile(.speechStandard)
        engine.setAudioScenario(.default)
        engine.setDefaultAudioRouteToSpeakerphone(true)
        engine.enableAudioVolumeIndication(200, smooth: 3, reportVad: false)
        engine.setEnableSpeakerphone(true)

        self.agoraKit = engine
        self.initializing = false
    }

    func destroyAgoraEngine() {
        AgoraRtcEngineKit.destroy()
        agoraKit = nil
    }

    // MARK: - Channel actions

    /// Joins a channel using a token + channel name + uid.
    /// Use `joinChannel(using:)` if you already have a `JoinCallResponse.AgoraConfig` from the API.
    func joinChannel(token: String, channelName: String, uid: UInt = 0) async {
        guard let engine = agoraKit else {
            agoraError = "AGORA_NOT_INITIALIZED"
            return
        }
        guard !inInACall else { return }

        currentChannel = channelName
        currentToken = token
        joiningChannel = true

        let options = AgoraRtcChannelMediaOptions()
        options.channelProfile = .communication
        options.clientRoleType = .broadcaster
        options.publishMicrophoneTrack = true
        options.publishCameraTrack = false
        options.autoSubscribeAudio = true
        options.autoSubscribeVideo = false

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            engine.joinChannel(
                byToken: token,
                channelId: channelName,
                uid: uid,
                mediaOptions: options
            ) { [weak self] _, _, _ in
                Task { @MainActor in
                    guard let self else {
                        continuation.resume()
                        return
                    }
                    self.inInACall = true
                    self.myConnectionState = .ready
                    self.mySpeakerState = .speaker
                    self.myMicState = .speaking
                    self.joiningChannel = false
                    continuation.resume()
                }
            }
        }
    }

    /// Convenience: join using the Agora config returned from `POST /bookings/{id}/join`.
    func joinChannel(using config: JoinCallResponse.AgoraConfig) async {
        await joinChannel(
            token: config.rtcToken,
            channelName: config.channelName,
            uid: UInt(config.uid)
        )
    }

    func leaveChannel() async {
        guard inInACall, let engine = agoraKit else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            engine.leaveChannel { [weak self] _ in
                Task { @MainActor in
                    self?.inInACall = false
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Audio controls

    func mutedMic() {
        guard inInACall, let engine = agoraKit else { return }
        engine.muteLocalAudioStream(true)
        myMicState = .muted
    }

    func unmutedMic() {
        guard inInACall, let engine = agoraKit else { return }
        engine.muteLocalAudioStream(false)
        myMicState = .speaking
    }

    func mutedSpeaker() {
        guard inInACall, let engine = agoraKit else { return }
        engine.adjustPlaybackSignalVolume(0)
        mySpeakerState = .muted
    }

    func useEar() {
        guard inInACall, let engine = agoraKit else { return }
        engine.setEnableSpeakerphone(false)
        engine.adjustPlaybackSignalVolume(100)
        mySpeakerState = .ear
    }

    func useSpeaker() {
        guard inInACall, let engine = agoraKit else { return }
        engine.setEnableSpeakerphone(true)
        engine.adjustPlaybackSignalVolume(100)
        mySpeakerState = .speaker
    }

    func resetValues() {
        inInACall = false
        currentChannel = nil
        currentToken = nil
        myConnectionState = .waiting
        remoteConnectionState = .waiting
        mySpeakerState = nil
        myMicState = nil
        remoteMicState = nil
        agoraError = nil
    }
}

// MARK: - AgoraRtcEngineDelegate
//
// Delegate methods come in on the SDK's worker thread. They are marked
// `nonisolated` so they don't inherit the @MainActor of the class; each
// hops back onto the main actor before touching @Published state.

extension AgoraManager: AgoraRtcEngineDelegate {

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorType: AgoraErrorCode) {
        let message: String?
        switch errorType {
        case .tokenExpired: message = "TOKEN_EXPIRED"
        case .invalidToken: message = "INVALID_TOKEN"
        default:            message = nil
        }
        guard let message else { return }
        Task { @MainActor [weak self] in
            self?.agoraError = message
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        Task { @MainActor [weak self] in
            self?.myConnectionState = .ready
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        Task { @MainActor [weak self] in
            self?.remoteConnectionState = .ready
        }
    }

    /// The SDK reports remote users only here (`uid` is never the local user),
    /// so this callback only ever changes the remote party's state. The local
    /// side is driven by `connectionChangedTo`.
    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        Task { @MainActor [weak self] in
            self?.remoteConnectionState = .disconnected
        }
    }

    /// Local connection state. A terminal `.failed` (the SDK gave up
    /// rejoining) moves the local state to `.disconnected`, which the call
    /// view model turns into the normal end path. See
    /// `ConnectionState.localState(for:)` for what is deliberately ignored.
    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        connectionChangedTo state: AgoraConnectionState,
        reason: AgoraConnectionChangedReason
    ) {
        let link = AgoraLinkState(rawValue: state.rawValue)
        guard let next = ConnectionState.localState(for: link) else { return }
        Task { @MainActor [weak self] in
            self?.myConnectionState = next
        }
    }

    nonisolated func rtcEngine(_ engine: AgoraRtcEngineKit, didRejoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        Task { @MainActor [weak self] in
            self?.myConnectionState = .ready
        }
    }

    /// 4.x replacement for the deprecated `didAudioMuted` callback. Maps the remote
    /// audio state to our binary muted/speaking model.
    nonisolated func rtcEngine(
        _ engine: AgoraRtcEngineKit,
        remoteAudioStateChangedOfUid uid: UInt,
        state: AgoraAudioRemoteState,
        reason: AgoraAudioRemoteReason,
        elapsed: Int
    ) {
        guard uid != 0 else { return }
        let nextState: MicState?
        switch state {
        case .stopped:                 nextState = .muted
        case .starting, .decoding:     nextState = .speaking
        case .frozen, .failed:         nextState = nil
        @unknown default:              nextState = nil
        }
        guard let nextState else { return }
        Task { @MainActor [weak self] in
            self?.remoteMicState = nextState
        }
    }
}
