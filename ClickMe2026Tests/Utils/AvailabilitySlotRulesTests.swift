//
//  AvailabilitySlotRulesTests.swift
//  ClickMe2026Tests
//
//  EXP-05 to EXP-07: the time-range sheet edits a draft and only Done writes
//  it, a stored off-grid or 24:00 time shows as a selected row, and 24:00
//  reads 12:00 AM. Pure rules plus the view-model commit; no network.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Availability slot rules")
struct AvailabilitySlotRulesTests {

    // MARK: Picker rows

    @Test("a stored off-grid start is a row, in time order")
    func offGridStartIsInserted() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: true, draftStart: 555, draftEnd: 1020, storedValue: 555)
        #expect(rows.contains(555))
        #expect(rows == rows.sorted())
        #expect(Array(rows.prefix(21).suffix(3)) == [540, 555, 570])
        #expect(rows.first == 0)
    }

    @Test("a stored 24:00 end is the last End row")
    func storedMidnightEndIsKept() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: false, draftStart: 1320, draftEnd: 1440, storedValue: 1440)
        #expect(Array(rows.suffix(4)) == [1350, 1380, 1410, 1440])
    }

    @Test("24:00 is never offered as a new End choice")
    func midnightNotOfferedNew() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: false, draftStart: 540, draftEnd: 600, storedValue: 600)
        #expect(!rows.contains(1440))
        #expect(rows.last == 1410)
    }

    @Test("a stored time already on the grid is not duplicated")
    func onGridStoredNoDuplicate() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: true, draftStart: 540, draftEnd: 600, storedValue: 540)
        #expect(rows.filter { $0 == 540 }.count == 1)
        #expect(rows == rows.sorted())
        #expect(Set(rows).count == rows.count)
    }

    @Test("a stored value the other draft value forbids is dropped")
    func forbiddenStoredValueDropped() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: true, draftStart: 555, draftEnd: 540, storedValue: 555)
        #expect(!rows.contains(555))
    }

    @Test("a 24:00 end leaves 23:30 as a valid start")
    func midnightEndLeavesLastGridStart() {
        let rows = AvailabilitySlotRules.pickerRows(isStart: true, draftStart: 1410, draftEnd: 1440, storedValue: 1410)
        #expect(rows.contains(1410))
    }

    // MARK: Labels

    @Test("1440 and 0 read 12:00 AM, 720 reads 12:00 PM")
    func amPmLabels() {
        #expect(minutesToAMPM(1440) == "12:00 AM")
        #expect(minutesToAMPM(0) == "12:00 AM")
        #expect(minutesToAMPM(720) == "12:00 PM")
        #expect(minutesToAMPM(555) == "9:15 AM")
        #expect(minutesToAMPM(1410) == "11:30 PM")
    }

    @Test("the day row keeps 24:00 for a stored 1440")
    func dayRowKeepsMidnight() {
        #expect(minutesToString(1440) == "24:00")
    }

    // MARK: Commit

    @Test("Done writes the draft to the slot, keeps its id and closes the sheet")
    func commitWritesDraft() {
        let vm = AvailabilitySettingsViewModel.previewSeed()
        let originalId = vm.schedule[0].slots[0].id
        vm.beginEditingSlot(dayIndex: 0, slotIndex: 0)
        #expect(vm.showTimePicker)

        vm.commitEditedSlot(AvailabilityTimeSlot(start: 600, end: 660))

        #expect(vm.schedule[0].slots[0].start == 600)
        #expect(vm.schedule[0].slots[0].end == 660)
        #expect(vm.schedule[0].slots[0].id == originalId)
        #expect(!vm.showTimePicker)
    }

    @Test("Cancel leaves the slot at its seeded times")
    func dismissLeavesSlot() {
        let vm = AvailabilitySettingsViewModel.previewSeed()
        let before = vm.schedule[0].slots[0]
        vm.beginEditingSlot(dayIndex: 0, slotIndex: 0)

        vm.dismissTimePicker()

        #expect(vm.schedule[0].slots[0].start == before.start)
        #expect(vm.schedule[0].slots[0].end == before.end)
        #expect(!vm.showTimePicker)
    }

    @Test("a commit with the slot index out of range changes nothing")
    func commitOutOfRangeIsNoOp() {
        let vm = AvailabilitySettingsViewModel.previewSeed()
        let before = vm.schedule[0].slots[0]
        vm.beginEditingSlot(dayIndex: 0, slotIndex: 7)

        vm.commitEditedSlot(AvailabilityTimeSlot(start: 600, end: 660))

        #expect(vm.schedule[0].slots.count == 1)
        #expect(vm.schedule[0].slots[0].start == before.start)
        #expect(vm.schedule[0].slots[0].end == before.end)
        #expect(!vm.showTimePicker)
    }

    // MARK: Add hours

    @Test("Add hours on an empty day adds 9:00 AM to 5:00 PM")
    func addHoursEmptyDay() throws {
        let slot = try #require(AvailabilitySlotRules.addHours(after: nil))
        #expect(slot.start == 540)
        #expect(slot.end == 1020)
    }

    @Test("Add hours after 22:00 gives 22:30 to 23:30")
    func addHoursAfterTenPM() throws {
        let slot = try #require(AvailabilitySlotRules.addHours(after: 1320))
        #expect(slot.start == 1350)
        #expect(slot.end == 1410)
    }

    @Test("an off-grid latest end flows through and the end is clamped")
    func addHoursOffGridEnd() throws {
        let slot = try #require(AvailabilitySlotRules.addHours(after: 1335))
        #expect(slot.start == 1365)
        #expect(slot.end == 1410)
    }

    @Test("Add hours after 10:00 AM gives 10:30 to 11:30")
    func addHoursMidday() throws {
        let slot = try #require(AvailabilitySlotRules.addHours(after: 600))
        #expect(slot.start == 630)
        #expect(slot.end == 690)
    }

    @Test("Add hours is unavailable when the new start would be 23:00 or later")
    func addHoursNoRoom() {
        for latestEnd in [1350, 1380, 1410, 1440] {
            #expect(AvailabilitySlotRules.addHours(after: latestEnd) == nil)
        }
    }

    @Test("a new slot never ends after 23:30 and always has end after start")
    func addHoursNeverPastLastGridTime() {
        for latestEnd in stride(from: 0, through: 1440, by: 15) {
            guard let slot = AvailabilitySlotRules.addHours(after: latestEnd) else { continue }
            #expect(slot.end <= 1410)
            #expect(slot.end > slot.start)
        }
    }
}
