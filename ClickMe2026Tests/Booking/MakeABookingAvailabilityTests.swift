//
//  MakeABookingAvailabilityTests.swift
//  ClickMe2026Tests
//
//  BOOK-02: changing month in Make a Booking never shows the previous month's
//  availability. Runs the real view model against a mocked URLSession that
//  answers `/availability` per requested month.
//

import Combine
import Foundation
import Testing
@testable import ClickMe2026

/// Numbers the requests a mocked handler sees. The handler runs on a URL
/// loading thread, so access goes through a lock.
private final class RequestCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var count = 0

    func next() -> Int {
        lock.lock(); defer { lock.unlock() }
        count += 1
        return count
    }
}

private enum AvailabilityFixture {
    static let serverText = "availability exploded"

    /// `yyyy-MM` for `date`, formatted the way the view model formats it.
    static func monthKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }

    /// `ExpertAvailabilityData` body for `month`: `expert_timezone` is
    /// `Zone/<tag>` and the single available slot is on the 15th at 15:00 UTC.
    nonisolated static func availabilityBody(month: String, zoneTag: String) -> Data {
        Data("""
        {"status":"success","data":{
          "expert_timezone":"Zone/\(zoneTag)","client_timezone":"UTC","month":"\(month)",
          "days":[{"date":"\(month)-15","slots":[
            {"start_utc":"\(month)-15T15:00:00.000Z","end_utc":"\(month)-15T15:30:00.000Z",
             "available":true,"held":false}]}]}}
        """.utf8)
    }

    nonisolated static func requestedMonth(_ request: URLRequest) -> String {
        guard let url = request.url,
              let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return "" }
        return items.first { $0.name == "month" }?.value ?? ""
    }

    nonisolated static func ok(_ request: URLRequest, body: Data) -> (HTTPURLResponse, Data) {
        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (http, body)
    }
}

@Suite("Make a Booking availability", .serialized)
@MainActor
struct MakeABookingAvailabilityTests {

    private func makeViewModel(api: ClickMeAPI) -> MakeABookingViewModel {
        MakeABookingViewModel(
            expertName: "Ada Lovelace",
            expertTitle: "Engineer",
            expertImageURL: "",
            topics: [],
            api: api
        )
    }

    /// Every `yyyy-MM` (UTC) that has at least one slot in the view model.
    private func slotMonths(_ viewModel: MakeABookingViewModel) -> Set<String> {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        let f = DateFormatter()
        f.calendar = utc
        f.timeZone = utc.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM"
        return Set(viewModel.availabilityByDate.values.flatMap { $0 }.map { f.string(from: $0.startTime) })
    }

    /// Polls (20 ms steps, up to 3 s) until `condition` holds.
    private func wait(until condition: () -> Bool) async {
        for _ in 0 ..< 150 {
            if condition() { break }
            try? await Task.sleep(for: .milliseconds(20))
        }
    }

    @Test("Previous then next month: ends on the starting month, never .failed, no slot from the superseded month")
    func fastMonthTapsEndOnDisplayedMonth() async {
        let api = APITestFactory.make { request in
            let month = AvailabilityFixture.requestedMonth(request)
            return AvailabilityFixture.ok(request, body: AvailabilityFixture.availabilityBody(month: month, zoneTag: month))
        }
        let viewModel = makeViewModel(api: api)
        let start = viewModel.displayedMonth
        let startKey = AvailabilityFixture.monthKey(start)
        let twoBack = AvailabilityFixture.monthKey(viewModel.calendar.date(byAdding: .month, value: -2, to: start)!)

        var states: [LoadState] = []
        let sink = viewModel.$availabilityState.sink { states.append($0) }
        defer { sink.cancel() }

        viewModel.goToPreviousMonth()
        viewModel.goToNextMonth()

        await wait { viewModel.availabilityState == .loaded }
        // Let any superseded load finish so a stale write would show up.
        try? await Task.sleep(for: .milliseconds(300))

        #expect(viewModel.availabilityState == .loaded)
        #expect(viewModel.calendar.isDate(viewModel.displayedMonth, equalTo: start, toGranularity: .month))
        #expect(viewModel.expertTimezone == "Zone/\(startKey)")
        #expect(!slotMonths(viewModel).contains(twoBack))
        #expect(slotMonths(viewModel).contains(startKey))
        #expect(!states.contains { if case .failed = $0 { return true } else { return false } })
    }

    @Test("An older load that lands last writes nothing")
    func olderLoadLandingLastWritesNothing() async {
        let counter = RequestCounter()
        // The first request is slow so the older load can finish after the
        // newer one. Each response is tagged with its request number; the
        // newer load's center request is number 2.
        let api = APITestFactory.make { request in
            let number = counter.next()
            if number == 1 { Thread.sleep(forTimeInterval: 0.3) }
            let month = AvailabilityFixture.requestedMonth(request)
            return AvailabilityFixture.ok(request, body: AvailabilityFixture.availabilityBody(month: month, zoneTag: "\(number)"))
        }
        let viewModel = makeViewModel(api: api)
        let month = viewModel.displayedMonth

        let older = Task { await viewModel.loadAvailability(for: month) }
        let newer = Task { await viewModel.loadAvailability(for: month) }
        await older.value
        await newer.value

        #expect(viewModel.availabilityState == .loaded)
        #expect(viewModel.expertTimezone == "Zone/2")
    }

    @Test("A load for a month that is no longer displayed writes nothing")
    func loadForOtherMonthWritesNothing() async {
        let api = APITestFactory.make { request in
            let month = AvailabilityFixture.requestedMonth(request)
            return AvailabilityFixture.ok(request, body: AvailabilityFixture.availabilityBody(month: month, zoneTag: month))
        }
        let viewModel = makeViewModel(api: api)
        let previous = viewModel.calendar.date(byAdding: .month, value: -1, to: viewModel.displayedMonth)!

        await viewModel.loadAvailability(for: previous)

        #expect(viewModel.availabilityByDate.isEmpty)
        #expect(viewModel.expertTimezone == nil)
        #expect(viewModel.availabilityState != .loaded)
    }

    @Test("A request that fails with URLError.cancelled is not a failure")
    func cancelledRequestIsNotFailure() async {
        let api = APITestFactory.make { _ in throw URLError(.cancelled) }
        let viewModel = makeViewModel(api: api)

        await viewModel.loadAvailability(for: viewModel.displayedMonth)

        #expect(viewModel.availabilityState == .loading)
    }

    @Test("A current load whose center month fails with a 500 shows the server message")
    func centerFailureShowsServerMessage() async {
        let api = APITestFactory.make { request in
            let http = HTTPURLResponse(
                url: request.url!,
                statusCode: 500,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = Data(#"{"status":"error","code":"INTERNAL_ERROR","message":"\#(AvailabilityFixture.serverText)"}"#.utf8)
            return (http, body)
        }
        let viewModel = makeViewModel(api: api)

        await viewModel.loadAvailability(for: viewModel.displayedMonth)

        #expect(viewModel.availabilityState == .failed(AvailabilityFixture.serverText))
    }
}
