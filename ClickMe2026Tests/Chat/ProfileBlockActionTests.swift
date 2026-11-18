//
//  ProfileBlockActionTests.swift
//  ClickMe2026Tests
//
//  CHAT-04 (D-05, D-06): Block {name} on the Expert Profile creates or finds the thread with
//  POST /chats/initiate, then blocks it with POST /chats/{id}/actions (action "block"), in that
//  order and once. Success shows the toast "You blocked {name}"; a failure shows an error and no
//  toast. Nothing here opens a chat.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Profile block", .serialized)
@MainActor
struct ProfileBlockActionTests {

    private typealias Fixtures = ClientBookingFixtures
    typealias Responder = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated private static let expertId = UUID(uuidString: "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb")!
    nonisolated private static let threadId = UUID(uuidString: "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa")!

    // MARK: Stub helpers

    nonisolated private static func isInitiate(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/chats/initiate") == true
    }

    nonisolated private static func isAction(_ request: URLRequest) -> Bool {
        request.httpMethod == "POST" && request.url?.path.hasSuffix("/actions") == true
    }

    nonisolated private static let initiateOK: Responder = { request in
        Fixtures.response(
            for: request,
            status: 201,
            body: Data(#"{"status":"success","data":{"thread_id":"\#(threadId.uuidString)"}}"#.utf8)
        )
    }

    nonisolated private static let actionOK: Responder = { request in
        Fixtures.response(for: request, body: Data(#"{"status":"success"}"#.utf8))
    }

    nonisolated private static func fail(_ status: Int, code: String, message: String) -> Responder {
        { request in
            Fixtures.response(for: request, status: status, body: Fixtures.errorBody(code: code, message: message))
        }
    }

    /// Routes POST /chats/initiate to `onInitiate` and POST /chats/{id}/actions to `onAction`; 404 otherwise.
    private static func makeAPI(onInitiate: @escaping Responder, onAction: @escaping Responder) -> ClickMeAPI {
        APITestFactory.make { request in
            if isInitiate(request) { return try onInitiate(request) }
            if isAction(request) { return try onAction(request) }
            return Fixtures.response(
                for: request,
                status: 404,
                body: Fixtures.errorBody(code: "NOT_FOUND", message: "Not found")
            )
        }
    }

    private func makeViewModel(api: ClickMeAPI, toasts: ToastCenter) -> ExpertProfileBlockViewModel {
        ExpertProfileBlockViewModel(api: api, toasts: toasts)
    }

    private static func newToasts() -> ToastCenter {
        ToastCenter(displayDuration: .seconds(60))
    }

    // MARK: Order and success

    @Test("block initiates the thread, then posts action block, once each, and toasts")
    func blockInitiatesThenBlocks() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: Self.initiateOK, onAction: Self.actionOK),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        let requests = MockURLProtocol.recordedRequests
        #expect(requests.count == 2)
        #expect(requests.first.map(Self.isInitiate) == true)
        let peer = requests.first?.jsonBodyForTest()?["peer_id"] as? String
        #expect(peer?.lowercased() == Self.expertId.uuidString.lowercased())
        #expect(requests.last.map(Self.isAction) == true)
        #expect(requests.last?.url?.path.contains(Self.threadId.uuidString) == true)
        #expect(requests.last?.jsonBodyForTest()?["action"] as? String == "block")
        #expect(toasts.current?.message == "You blocked Dr. Test")
        #expect(toasts.current?.systemImage == "checkmark.circle.fill")
        #expect(viewModel.apiError == nil)
    }

    @Test("a failed initiate sends no block request, sets the error and shows no toast")
    func initiateFails() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(
                onInitiate: Self.fail(500, code: "INTERNAL_ERROR", message: "Server broke"),
                onAction: Self.actionOK
            ),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(MockURLProtocol.recordedRequests.filter(Self.isAction).isEmpty)
        #expect(viewModel.apiError == "Server broke")
        #expect(toasts.current == nil)
    }

    @Test("a failed block shows the server message and no toast")
    func actionFails() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(
                onInitiate: Self.initiateOK,
                onAction: Self.fail(500, code: "INTERNAL_ERROR", message: "Server broke")
            ),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(viewModel.apiError == "Server broke")
        #expect(toasts.current == nil)
    }

    // MARK: Names

    @Test("an empty or blank name reads as this user in the toast")
    func blankNameFallsBack() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: Self.initiateOK, onAction: Self.actionOK),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "  ")
        await viewModel.awaitBlock()

        #expect(toasts.current?.message == "You blocked this user")
        #expect(ExpertProfileBlockViewModel.displayName("") == "this user")
        #expect(ExpertProfileBlockViewModel.displayName(" \n ") == "this user")
        #expect(ExpertProfileBlockViewModel.displayName("Dr. Test") == "Dr. Test")
    }

    // MARK: In flight

    @Test("isBlocking is true while the request runs and false afterwards")
    func isBlockingTracksTheRequest() async {
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: Self.initiateOK, onAction: Self.actionOK),
            toasts: Self.newToasts()
        )
        #expect(viewModel.isBlocking == false)

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        #expect(viewModel.isBlocking == true)

        await viewModel.awaitBlock()
        #expect(viewModel.isBlocking == false)
    }

    // MARK: Failure copy

    @Test("a 404 on initiate reads as this user is unavailable and sends no block request")
    func initiateNotFound() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(
                onInitiate: Self.fail(404, code: "NOT_FOUND", message: "User not found."),
                onAction: Self.actionOK
            ),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(viewModel.apiError == "This user is unavailable.")
        #expect(ExpertProfileBlockViewModel.unavailableMessage == "This user is unavailable.")
        #expect(MockURLProtocol.recordedRequests.filter(Self.isAction).isEmpty)
        #expect(toasts.current == nil)
    }

    @Test("a transport error on initiate reads as a connection problem")
    func initiateTransportError() async {
        let toasts = Self.newToasts()
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: { _ in throw URLError(.notConnectedToInternet) }, onAction: Self.actionOK),
            toasts: toasts
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(viewModel.apiError == "Check your connection and try again.")
        #expect(toasts.current == nil)
    }

    @Test("a transport error on the block step reads as a connection problem")
    func actionTransportError() async {
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: Self.initiateOK, onAction: { _ in throw URLError(.timedOut) }),
            toasts: Self.newToasts()
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(viewModel.apiError == "Check your connection and try again.")
    }

    @Test("a 404 on the block step shows the server message, not the unavailable copy")
    func actionNotFound() async {
        let viewModel = makeViewModel(
            api: Self.makeAPI(
                onInitiate: Self.initiateOK,
                onAction: Self.fail(404, code: "NOT_FOUND", message: "Thread not found.")
            ),
            toasts: Self.newToasts()
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        #expect(viewModel.apiError == "Thread not found.")
    }

    // MARK: Repeat taps

    @Test("block called twice before the first finishes sends one initiate and one block")
    func repeatBlockSendsOnce() async {
        let viewModel = makeViewModel(
            api: Self.makeAPI(onInitiate: Self.initiateOK, onAction: Self.actionOK),
            toasts: Self.newToasts()
        )

        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        viewModel.block(peerId: Self.expertId, peerName: "Dr. Test")
        await viewModel.awaitBlock()

        let requests = MockURLProtocol.recordedRequests
        #expect(requests.filter(Self.isInitiate).count == 1)
        #expect(requests.filter(Self.isAction).count == 1)
    }
}
