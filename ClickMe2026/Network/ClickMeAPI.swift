//
//  ClickMeAPI.swift
//  ClickMeAPI
//
//  Created by Leon Chen on 2021-05-28.
//

import Foundation

// MARK: - List payload wrappers
// Many GET endpoints return `data: { <named_array>: [...] }`. These small wrappers
// decode the named-array layer so call sites can read `.data.<name>` directly.

struct CategoriesPayload: Decodable        { let categories: [Category] }
struct CurrenciesPayload: Decodable        { let currencies: [CurrencyItem] }
struct ExpertiseTagsPayload: Decodable     { let tags: [ExpertiseTagItem] }
struct LanguagesPayload: Decodable         { let languages: [LanguageItem] }
struct FeedbackTypesPayload: Decodable     { let types: [FeedbackTypeItem] }

struct FaqsPayload: Decodable {
    let categories: [FaqCategory]
    let trendingArticles: [FaqArticlePreview]?
}
struct FaqSearchPayload: Decodable         { let articles: [FaqSearchResult] }

struct ExpertsSearchPayload: Decodable {
    let experts: [ExpertSearchResultItem]
    let pagination: PaginationMeta?
}
struct DiscoveryFeedPayload: Decodable {
    let sections: [DiscoveryFeedSection]
    let pagination: PaginationMeta?
}
struct RandomExpertsPayload: Decodable {
    let experts: [RandomExpertItem]
    let pagination: PaginationMeta?
}
struct FavoritesPayload: Decodable {
    let experts: [FavoriteExpertItem]
    let pagination: PaginationMeta?
}

struct ExpertTopicsPayload: Decodable      { let topics: [ExpertTopicItem] }
struct ExpertReviewsPayload: Decodable {
    let summary: ReviewSummary
    let reviews: [ReviewItem]
    let pagination: PaginationMeta?
}

struct AvailabilityOverridesPayload: Decodable { let overrides: [AvailabilityOverrideItem] }

struct ClientBookingsPayload: Decodable {
    let bookings: [ClientBookingItem]
    let pagination: PaginationMeta?
}
struct ExpertBookingsPayload: Decodable {
    let bookings: [ExpertBookingItem]
    let pagination: PaginationMeta?
}
struct BookingRequestsPayload: Decodable {
    let requests: [BookingRequestItem]
    let pagination: PaginationMeta?
}

struct ChatsPayload: Decodable {
    let threads: [ChatThreadItem]
    let pagination: PaginationMeta?
}
struct ChatMessagesPayload: Decodable {
    let messages: [ChatMessageItem]
    let pagination: PaginationMeta?
}
struct InitiateChatPayload: Decodable      { let threadId: UUID }

struct NotificationsPayload: Decodable {
    let notifications: [NotificationItem]
    let pagination: PaginationMeta?
}

// MARK: - ClickMeAPI core
//
// Endpoint methods are organized per feature in `ClickMeAPI+<Feature>.swift`
// extension files. This file holds the class definition, shared state, and URL
// helpers that the extensions rely on.

final class ClickMeAPI {

    static let shared = ClickMeAPI()

    let service: NetworkService
    var baseURL: String

    var bearerToken: String? {
        get { service.bearerToken }
        set { service.bearerToken = newValue }
    }

    init(
        baseURL: String = AppEnvironment.current.baseURL,
        service: NetworkService = NetworkService()
    ) {
        self.baseURL = baseURL
        self.service = service
    }

    // MARK: URL helpers (internal so feature extensions can use them)

    func url(_ endpoint: APIRequestURLs) -> String {
        baseURL + endpoint.path
    }

    func url(_ endpoint: APIRequestURLs, id: UUID) -> String {
        baseURL + endpoint.path.replacingOccurrences(of: ":id", with: id.uuidString)
    }

    func url(_ endpoint: APIRequestURLs, deviceId: String) -> String {
        baseURL + endpoint.path.replacingOccurrences(of: ":device_id", with: deviceId)
    }
}
