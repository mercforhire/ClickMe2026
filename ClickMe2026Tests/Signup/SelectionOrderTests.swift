//
//  SelectionOrderTests.swift
//  ClickMe2026Tests
//
//  SIGN-03: the signup pickers keep the order the user tapped in. The first
//  expertise tag is the one the server stores as primary
//  (`onboarding.controller.js`, `is_primary: idx === 0`), so re-sorting the
//  selection by the catalog's alphabetical order made the wrong tag primary.
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Selection order", .serialized)
struct SelectionOrderTests {

    // MARK: - Fixtures

    private static let brand = ExpertiseTagItem(
        id: UUID(uuidString: "AAAAAAAA-0000-4000-8000-000000000001")!,
        label: "Brand",
        categoryId: "business"
    )
    private static let content = ExpertiseTagItem(
        id: UUID(uuidString: "AAAAAAAA-0000-4000-8000-000000000002")!,
        label: "Content",
        categoryId: "creative"
    )
    private static let data = ExpertiseTagItem(
        id: UUID(uuidString: "AAAAAAAA-0000-4000-8000-000000000003")!,
        label: "Data",
        categoryId: "technology"
    )
    private static let catalog = [brand, content, data]

    /// A client whose every request succeeds with a minimal setup-profile body.
    private static func makeAPI() -> ClickMeAPI {
        APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = """
            {"status":"success","data":{"profile_id":"BBBBBBBB-0000-4000-8000-000000000001",\
            "completion_percentage":10,"missing_fields":[],"next_recommended_step":null,\
            "setup_completed":false}}
            """
            return (response, Data(body.utf8))
        }
    }

    // MARK: - Tags

    @Test("Tags list in tap order, not catalog order")
    func tagsFollowTapOrder() {
        let accumulator = SignupAccumulator()
        let vm = SignupTagsViewModel(accumulator: accumulator)
        vm.allTags = Self.catalog

        vm.toggleTag(Self.data)
        vm.toggleTag(Self.brand)

        #expect(vm.selectedTags.map(\.id) == [Self.data.id, Self.brand.id])
        #expect(accumulator.expertiseTags.map(\.id) == [Self.data.id, Self.brand.id])
    }

    @Test("Deselecting removes a tag from the order and reselecting appends it")
    func deselectThenReselectAppends() {
        let vm = SignupTagsViewModel(accumulator: SignupAccumulator())
        vm.allTags = Self.catalog

        vm.toggleTag(Self.data)
        vm.toggleTag(Self.brand)
        vm.toggleTag(Self.data)
        #expect(vm.selectedTags.map(\.id) == [Self.brand.id])

        vm.toggleTag(Self.data)
        #expect(vm.selectedTags.map(\.id) == [Self.brand.id, Self.data.id])
    }

    @Test("removeTag drops the tag and keeps the rest in order")
    func removeTagKeepsOrder() {
        let accumulator = SignupAccumulator()
        let vm = SignupTagsViewModel(accumulator: accumulator)
        vm.allTags = Self.catalog

        vm.toggleTag(Self.brand)
        vm.toggleTag(Self.data)
        vm.removeTag(Self.brand)

        #expect(vm.selectedTags.map(\.id) == [Self.data.id])
        #expect(vm.selectedIds == [Self.data.id])
        #expect(accumulator.expertiseTags.map(\.id) == [Self.data.id])
    }

    @Test("An accumulator seed keeps its order and shows before the catalog loads")
    func seedKeepsOrderWithoutCatalog() {
        let accumulator = SignupAccumulator()
        accumulator.expertiseTags = [Self.content, Self.brand]

        let vm = SignupTagsViewModel(accumulator: accumulator)

        #expect(vm.allTags.isEmpty)
        #expect(vm.selectedTags.map(\.id) == [Self.content.id, Self.brand.id])
    }

    @Test("A seeded order survives the catalog loading alphabetically")
    func seedOrderSurvivesCatalog() {
        let accumulator = SignupAccumulator()
        accumulator.expertiseTags = [Self.content, Self.brand]
        let vm = SignupTagsViewModel(accumulator: accumulator)

        vm.allTags = Self.catalog

        #expect(vm.selectedTags.map(\.id) == [Self.content.id, Self.brand.id])
    }

    @Test("save() sends expertise_tags in tap order")
    func saveSendsTapOrder() async throws {
        let api = Self.makeAPI()
        let vm = SignupTagsViewModel(accumulator: SignupAccumulator(), api: api)
        vm.allTags = Self.catalog

        vm.toggleTag(Self.data)
        vm.toggleTag(Self.brand)
        let saved = await vm.save()

        #expect(saved)
        let request = try #require(MockURLProtocol.recordedRequests.last)
        let body = try #require(request.jsonBodyForTest())
        let tags = try #require(body["expertise_tags"] as? [String])
        #expect(tags == [Self.data.id.uuidString, Self.brand.id.uuidString])
    }

    // MARK: - Languages

    private static let english = LanguageItem(id: "en", label: "English")
    private static let french = LanguageItem(id: "fr", label: "French")
    private static let spanish = LanguageItem(id: "es", label: "Spanish")
    /// Alphabetical, like the sorted `getLanguages` response.
    private static let languageCatalog = [english, french, spanish]

    @Test("An initial language selection keeps its order before the catalog loads")
    func languageSeedKeepsOrderWithoutCatalog() {
        let vm = LanguageSelectionViewModel(initialSelection: [Self.spanish, Self.english])

        #expect(vm.allLanguages.isEmpty)
        #expect(vm.orderedSelection.map(\.id) == ["es", "en"])
    }

    @Test("A seeded language order survives the catalog loading alphabetically")
    func languageSeedOrderSurvivesCatalog() {
        let vm = LanguageSelectionViewModel(initialSelection: [Self.spanish, Self.english])

        vm.allLanguages = Self.languageCatalog

        #expect(vm.orderedSelection.map(\.id) == ["es", "en"])
    }

    @Test("Languages toggle in tap order and deselecting removes from the order")
    func languageToggleFollowsTapOrder() {
        let vm = LanguageSelectionViewModel(initialSelection: [Self.spanish, Self.english])
        vm.allLanguages = Self.languageCatalog

        vm.toggle(Self.french)
        #expect(vm.orderedSelection.map(\.id) == ["es", "en", "fr"])

        vm.toggle(Self.english)
        #expect(vm.orderedSelection.map(\.id) == ["es", "fr"])
        #expect(vm.selected == ["es", "fr"])

        vm.toggle(Self.english)
        #expect(vm.orderedSelection.map(\.id) == ["es", "fr", "en"])
    }

    @Test("Basic Info save() sends languages in the order they were set")
    func basicInfoSaveSendsLanguageOrder() async throws {
        let api = Self.makeAPI()
        let vm = SignupBasicInfoViewModel(accumulator: SignupAccumulator(), api: api)
        vm.firstName = "Ana"
        vm.city = "Toronto"
        vm.countryCode = "CAN"

        vm.setLanguages([Self.spanish, Self.english])
        let saved = await vm.save()

        #expect(saved)
        let request = try #require(MockURLProtocol.recordedRequests.last)
        let body = try #require(request.jsonBodyForTest())
        let languages = try #require(body["languages"] as? [String])
        #expect(languages == ["es", "en"])
    }
}
