//
//  PushRoutePlannerTests.swift
//  ClickMe2026Tests
//
//  PUSH-02, PUSH-03, BOOK-15: a tapped push switches mode from `target_role`
//  before it is routed (D-02), never forces an account without the expert
//  role or a completed expert setup into expert mode (D-03), and is held
//  while the account's roles are unknown instead of being decided from a
//  nil `me` (T-02-28). `PushAccountSource` is faked here, so no test reaches
//  the network.
//

import Foundation
import Testing
@testable import ClickMe2026

@Suite("Push route planner", .serialized)
@MainActor
struct PushRoutePlannerTests {

    private nonisolated static let a = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    private nonisolated static let d = PushDestination.bookingDetail(bookingId: a)

    // MARK: - Fakes

    /// A scripted stand-in for `UserManager`: what the roles and expert setup
    /// read as, and what `loadRoles` changes them to.
    @MainActor
    private final class FakeAccount {
        var roles: [UserRole]?
        var setupCompleted: Bool?
        var loadRolesCalls = 0
        var loadExpertProfileCalls = 0
        var onLoadRoles: () -> Void = {}
        var onLoadExpertProfile: () -> Void = {}

        init(roles: [UserRole]?, setupCompleted: Bool?) {
            self.roles = roles
            self.setupCompleted = setupCompleted
        }

        var source: PushAccountSource {
            PushAccountSource(
                roles: { self.roles },
                expertSetupCompleted: { self.setupCompleted },
                loadRoles: {
                    self.loadRolesCalls += 1
                    self.onLoadRoles()
                },
                loadExpertProfile: {
                    self.loadExpertProfileCalls += 1
                    self.onLoadExpertProfile()
                }
            )
        }
    }

    private static func event(_ data: [AnyHashable: Any]) -> PushEvent {
        PushEvent(userInfo: data)
    }

    // MARK: - plan

    @Test("plan keeps or switches the mode from the target role", arguments: [
        (target: AppMode?.none, current: AppMode.client, canUse: true, destination: d, switchTo: AppMode?.none),
        (target: AppMode?.none, current: AppMode.expert, canUse: false, destination: d, switchTo: AppMode?.none),
        (target: .client, current: .client, canUse: true, destination: d, switchTo: nil),
        (target: .expert, current: .expert, canUse: false, destination: d, switchTo: nil),
        (target: .expert, current: .client, canUse: true, destination: d, switchTo: .expert),
        (target: .expert, current: .client, canUse: false, destination: .notificationsList, switchTo: nil),
        (target: .client, current: .expert, canUse: true, destination: d, switchTo: .client),
        (target: .client, current: .expert, canUse: false, destination: d, switchTo: .client),
    ])
    func planRows(
        _ row: (target: AppMode?, current: AppMode, canUse: Bool, destination: PushDestination, switchTo: AppMode?)
    ) {
        let pending = PendingPush(destination: Self.d, targetRole: row.target)
        let plan = PushRoutePlanner.plan(pending, currentMode: row.current, canUseExpertMode: row.canUse)
        #expect(plan == PushPlan(destination: row.destination, switchToMode: row.switchTo))
    }

    @Test("expert mode needs the expert role and a completed setup")
    func canUseExpertMode() {
        #expect(PushRoutePlanner.canUseExpertMode(roles: [.client, .expert], setupCompleted: true))
        #expect(!PushRoutePlanner.canUseExpertMode(roles: [.client], setupCompleted: true))
        #expect(!PushRoutePlanner.canUseExpertMode(roles: [.client, .expert], setupCompleted: false))
        #expect(!PushRoutePlanner.canUseExpertMode(roles: nil, setupCompleted: true))
        #expect(!PushRoutePlanner.canUseExpertMode(roles: [.client, .expert], setupCompleted: nil))
    }

    @Test("roles are needed only for an expert-targeted tap in client mode")
    func needsRoles() {
        let expertTap = PendingPush(destination: Self.d, targetRole: .expert)
        let clientTap = PendingPush(destination: Self.d, targetRole: .client)
        let untargeted = PendingPush(destination: Self.d, targetRole: nil)

        #expect(PushRoutePlanner.needsRoles(expertTap, currentMode: .client))
        #expect(!PushRoutePlanner.needsRoles(expertTap, currentMode: .expert))
        #expect(!PushRoutePlanner.needsRoles(clientTap, currentMode: .client))
        #expect(!PushRoutePlanner.needsRoles(clientTap, currentMode: .expert))
        #expect(!PushRoutePlanner.needsRoles(untargeted, currentMode: .client))
        #expect(!PushRoutePlanner.needsRoles(untargeted, currentMode: .expert))
    }

    // MARK: - planPending

    private nonisolated static let expertRequest = PendingPush(
        destination: .incomingRequest(bookingId: a),
        targetRole: .expert
    )

    @Test("an expert tap with unknown roles reloads them once and stays queued when they stay unknown")
    func unknownRolesStayQueued() async {
        let router = PushRouter.shared
        router.pending = Self.expertRequest
        defer { router.pending = nil }
        let account = FakeAccount(roles: nil, setupCompleted: nil)

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == nil)
        #expect(account.loadRolesCalls == 1)
        #expect(router.pending == Self.expertRequest)
    }

    @Test("an expert tap with unknown roles is planned once the reload brings them")
    func rolesLoadedByReload() async {
        let router = PushRouter.shared
        router.pending = Self.expertRequest
        defer { router.pending = nil }
        let account = FakeAccount(roles: nil, setupCompleted: true)
        account.onLoadRoles = { account.roles = [.client, .expert] }

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == PushPlan(destination: .incomingRequest(bookingId: Self.a), switchToMode: .expert))
        #expect(account.loadRolesCalls == 1)
    }

    @Test("a client-only account is decided from its known roles without a reload")
    func knownClientOnlyRoles() async {
        let router = PushRouter.shared
        router.pending = Self.expertRequest
        defer { router.pending = nil }
        let account = FakeAccount(roles: [.client], setupCompleted: nil)

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == PushPlan(destination: .notificationsList, switchToMode: nil))
        #expect(account.loadRolesCalls == 0)
        #expect(account.loadExpertProfileCalls == 0)
    }

    @Test("an untargeted tap is planned without reading roles")
    func untargetedTapNeedsNoRoles() async {
        let router = PushRouter.shared
        router.pending = PendingPush(destination: Self.d, targetRole: nil)
        defer { router.pending = nil }
        let account = FakeAccount(roles: nil, setupCompleted: nil)

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == PushPlan(destination: Self.d, switchToMode: nil))
        #expect(account.loadRolesCalls == 0)
    }

    @Test("an expert account with no loaded setup fetches the expert profile once; a failed fetch counts as cannot")
    func missingExpertSetupIsFetchedOnce() async {
        let router = PushRouter.shared
        router.pending = Self.expertRequest
        defer { router.pending = nil }
        let account = FakeAccount(roles: [.client, .expert], setupCompleted: nil)

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == PushPlan(destination: .notificationsList, switchToMode: nil))
        #expect(account.loadExpertProfileCalls == 1)
        #expect(account.loadRolesCalls == 0)
    }

    @Test("nothing queued plans nothing")
    func nothingQueued() async {
        let router = PushRouter.shared
        router.pending = nil
        let account = FakeAccount(roles: [.client, .expert], setupCompleted: true)

        let plan = await router.planPending(currentMode: .client, account: account.source)

        #expect(plan == nil)
    }

    // MARK: - handleTap

    @Test("a booking-request tap for the expert role queues that request with the expert target")
    func requestTapQueuesExpertTarget() {
        let router = PushRouter.shared
        router.pending = nil
        defer { router.pending = nil }

        router.handleTap(Self.event([
            "route_category": "booking",
            "route_sub_category": "requests",
            "booking_id": Self.a.uuidString,
            "target_role": "expert",
        ]), isSignedIn: true)

        #expect(router.pending == PendingPush(destination: .incomingRequest(bookingId: Self.a), targetRole: .expert))
    }

    @Test("a payment_actions tap for the client role queues that booking with the client target (BOOK-15)")
    func paymentActionsTapQueuesBooking() {
        let router = PushRouter.shared
        router.pending = nil
        defer { router.pending = nil }

        router.handleTap(Self.event([
            "route_category": "booking",
            "route_sub_category": "payment_actions",
            "booking_id": Self.a.uuidString,
            "target_role": "client",
        ]), isSignedIn: true)

        #expect(router.pending == PendingPush(destination: .bookingDetail(bookingId: Self.a), targetRole: .client))
    }

    @Test("a tap while no account is signed in is dropped")
    func signedOutTapIsDropped() {
        let router = PushRouter.shared
        router.pending = nil
        defer { router.pending = nil }

        router.handleTap(Self.event([
            "route_category": "booking",
            "route_sub_category": "requests",
            "booking_id": Self.a.uuidString,
        ]), isSignedIn: false)

        #expect(router.pending == nil)
    }

    @Test("the later of two taps is the one queued")
    func laterTapWins() {
        let router = PushRouter.shared
        router.pending = nil
        defer { router.pending = nil }

        router.handleTap(Self.event([
            "route_category": "booking",
            "route_sub_category": "requests",
            "booking_id": Self.a.uuidString,
            "target_role": "expert",
        ]), isSignedIn: true)
        router.handleTap(Self.event([
            "route_category": "account",
            "route_sub_category": "password_changed",
        ]), isSignedIn: true)

        #expect(router.pending == PendingPush(destination: .accountSecurity, targetRole: nil))
    }

    @Test("a tap with no route_category and no known event_type opens the notifications list")
    func unroutableTapOpensNotifications() {
        let router = PushRouter.shared
        router.pending = nil
        defer { router.pending = nil }

        router.handleTap(Self.event(["event_type": "SOMETHING_ELSE"]), isSignedIn: true)

        #expect(router.pending == PendingPush(destination: .notificationsList, targetRole: nil))
    }
}
