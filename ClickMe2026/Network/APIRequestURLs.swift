//
//  APIRequestURLs.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-19.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
    case head   = "HEAD"
    case options = "OPTIONS"
}

enum APIRequestURLs {

    // MARK: Auth
    case login
    case forgotPassword
    case resetPassword

    // MARK: Me
    case getMe

    // MARK: Expert Profile
    case setupExpertProfile
    case updateExpertProfile

    // MARK: Meta
    case getExpertiseTags
    case getCurrencies
    case getLanguages

    // MARK: User Profile
    case getUserProfile
    case updateProfessionalDetails
    case updateLocation
    case updateLanguages
    case uploadAvatar

    // MARK: Discovery
    case getClientHome
    case searchExperts
    case getDiscoveryFeed
    case getRandomExperts
    case recordInteraction
    case getExpertDetails
    case getExpertTopics
    case getExpert

    // MARK: Availability
    case getMyAvailability
    case updateMyAvailability
    case getAvailabilityOverrides
    case createAvailabilityOverride
    case deleteAvailabilityOverride
    case getExpertAvailability

    // MARK: Booking
    case initiateBooking
    case createPaymentIntent
    case confirmBooking
    case requestBooking
    case getClientBookings
    case rescheduleClientBooking
    case cancelClientBooking
    case getExpertBookings
    case getExpertBookingDetails
    case getExpertBookingSummary
    case updateBookingTakeaways
    case updateBookingStatus
    case rescheduleExpertBooking
    case cancelExpertBooking
    case acceptExpertBooking
    case declineExpertBooking
    case getBookingRequests
    case getBookingRequest
    case acceptBookingRequest
    case declineBookingRequest
    case getBookingNote
    case createBookingNote

    // MARK: Call
    case joinCall
    case confirmCallConnection
    case endCall

    // MARK: Chats
    case initiateChat
    case getChats
    case getChatMessages
    case sendChatMessage
    case chatActions

    // MARK: Notifications
    case registerDeviceToken
    case unregisterDeviceToken
    case getNotifications
    case updateNotificationPreferences

    // MARK: Reviews
    case postReview
    case getReviewContext
    case getExpertReviews

    // MARK: Analytics
    case getAnalyticsSummary
    case getAnalyticsTrends
    case getPopularTopics

    // MARK: Feedback
    case getFeedbackTypes
    case submitFeedback

    // MARK: Support
    case getFAQs
    case searchFAQs
    case getFAQArticle
    case createSupportTicket

    // MARK: Media
    case uploadMedia

    // MARK: Account
    case requestAccountDeletion
    case deleteAccount

    var path: String {
        switch self {
        // Auth
        case .login:          return "/auth/login"
        case .forgotPassword: return "/auth/password/forgot"
        case .resetPassword:  return "/auth/password/reset"

        // Me
        case .getMe: return "/me"

        // Expert Profile
        case .setupExpertProfile:  return "/expert/profile/setup"
        case .updateExpertProfile: return "/expert/profile"

        // Meta
        case .getExpertiseTags: return "/meta/expertise-tags"
        case .getCurrencies:    return "/meta/currencies"
        case .getLanguages:     return "/meta/languages"

        // User Profile
        case .getUserProfile:            return "/user/profile"
        case .updateProfessionalDetails: return "/user/profile/professional"
        case .updateLocation:            return "/user/profile/location"
        case .updateLanguages:           return "/user/profile/languages"
        case .uploadAvatar:              return "/user/profile/avatar"

        // Discovery
        case .getClientHome:     return "/client/home"
        case .searchExperts:     return "/experts/search"
        case .getDiscoveryFeed:  return "/discovery/feed"
        case .getRandomExperts:  return "/discovery/random"
        case .recordInteraction: return "/discovery/interact"
        case .getExpertDetails:  return "/experts/:id/details"
        case .getExpertTopics:   return "/experts/:id/topics"
        case .getExpert:         return "/experts/:id"

        // Availability
        case .getMyAvailability,
             .updateMyAvailability:       return "/expert/availability"
        case .getAvailabilityOverrides,
             .createAvailabilityOverride: return "/expert/availability/overrides"
        case .deleteAvailabilityOverride: return "/expert/availability/overrides/:id"
        case .getExpertAvailability:      return "/experts/:id/availability"

        // Booking
        case .initiateBooking:         return "/bookings/initiate"
        case .createPaymentIntent:     return "/bookings/payment-intent"
        case .confirmBooking:          return "/bookings/confirm"
        case .requestBooking:          return "/bookings/request"
        case .getClientBookings:       return "/client/bookings"
        case .rescheduleClientBooking: return "/client/bookings/:id/reschedule"
        case .cancelClientBooking:     return "/client/bookings/:id/cancel"
        case .getExpertBookings:       return "/expert/bookings"
        case .getExpertBookingDetails: return "/expert/bookings/:id/details"
        case .getExpertBookingSummary: return "/expert/bookings/:id/summary"
        case .updateBookingTakeaways:  return "/expert/bookings/:id/takeaways"
        case .updateBookingStatus:     return "/expert/bookings/:id/status"
        case .rescheduleExpertBooking: return "/expert/bookings/:id/reschedule"
        case .cancelExpertBooking:     return "/expert/bookings/:id/cancel"
        case .acceptExpertBooking:     return "/expert/bookings/:id/accept"
        case .declineExpertBooking:    return "/expert/bookings/:id/decline"
        case .getBookingRequests:      return "/expert/booking-requests"
        case .getBookingRequest:       return "/expert/booking-requests/:id"
        case .acceptBookingRequest:    return "/expert/booking-requests/:id/accept"
        case .declineBookingRequest:   return "/expert/booking-requests/:id/decline"
        case .getBookingNote,
             .createBookingNote:       return "/bookings/:id/note"

        // Call
        case .joinCall:              return "/bookings/:id/join"
        case .confirmCallConnection: return "/bookings/:id/confirm-connection"
        case .endCall:               return "/bookings/:id/end"

        // Chats
        case .initiateChat:    return "/chats/initiate"
        case .getChats:        return "/chats"
        case .getChatMessages: return "/chats/:id/messages"
        case .sendChatMessage: return "/chats/:id/send"
        case .chatActions:     return "/chats/:id/actions"

        // Notifications
        case .registerDeviceToken:           return "/notifications/tokens"
        case .unregisterDeviceToken:         return "/notifications/tokens/:device_id"
        case .getNotifications:              return "/notifications"
        case .updateNotificationPreferences: return "/notifications/preferences"

        // Reviews
        case .postReview:       return "/bookings/:id/reviews"
        case .getReviewContext: return "/bookings/:id/reviews/context"
        case .getExpertReviews: return "/experts/:id/reviews"

        // Analytics
        case .getAnalyticsSummary: return "/expert/analytics/summary"
        case .getAnalyticsTrends:  return "/expert/analytics/trends"
        case .getPopularTopics:    return "/expert/analytics/popular-topics"

        // Feedback
        case .getFeedbackTypes: return "/feedback/types"
        case .submitFeedback:   return "/feedback/submit"

        // Support
        case .getFAQs:            return "/help/faqs"
        case .searchFAQs:         return "/help/faqs/search"
        case .getFAQArticle:      return "/help/faqs/articles/:id"
        case .createSupportTicket: return "/help/support/tickets"

        // Media
        case .uploadMedia: return "/media/upload"

        // Account
        case .requestAccountDeletion: return "/user/account/delete-request"
        case .deleteAccount:          return "/user/account"
        }
    }

    func getHTTPMethod() -> HTTPMethod {
        switch self {
        // Auth
        case .login, .forgotPassword, .resetPassword:
            return .post

        // Me
        case .getMe:
            return .get

        // Expert Profile
        case .setupExpertProfile, .updateExpertProfile:
            return .patch

        // Meta
        case .getExpertiseTags, .getCurrencies, .getLanguages:
            return .get

        // User Profile
        case .getUserProfile:
            return .get
        case .updateProfessionalDetails, .updateLocation:
            return .patch
        case .updateLanguages:
            return .put
        case .uploadAvatar:
            return .post

        // Discovery
        case .getClientHome, .searchExperts, .getDiscoveryFeed, .getRandomExperts,
             .getExpertDetails, .getExpertTopics, .getExpert:
            return .get
        case .recordInteraction:
            return .post

        // Availability
        case .getMyAvailability, .getAvailabilityOverrides, .getExpertAvailability:
            return .get
        case .updateMyAvailability:
            return .put
        case .createAvailabilityOverride:
            return .post
        case .deleteAvailabilityOverride:
            return .delete

        // Booking
        case .initiateBooking, .createPaymentIntent, .confirmBooking, .requestBooking,
             .cancelClientBooking, .cancelExpertBooking, .acceptExpertBooking,
             .declineExpertBooking, .acceptBookingRequest, .declineBookingRequest,
             .createBookingNote:
            return .post
        case .getClientBookings, .getExpertBookings, .getExpertBookingDetails,
             .getExpertBookingSummary, .getBookingRequests, .getBookingRequest,
             .getBookingNote:
            return .get
        case .rescheduleClientBooking, .updateBookingStatus, .rescheduleExpertBooking:
            return .patch
        case .updateBookingTakeaways:
            return .put

        // Call
        case .joinCall, .endCall:
            return .post
        case .confirmCallConnection:
            return .patch

        // Chats
        case .initiateChat, .sendChatMessage, .chatActions:
            return .post
        case .getChats, .getChatMessages:
            return .get

        // Notifications
        case .registerDeviceToken:
            return .post
        case .unregisterDeviceToken:
            return .delete
        case .getNotifications:
            return .get
        case .updateNotificationPreferences:
            return .patch

        // Reviews
        case .postReview:
            return .post
        case .getReviewContext, .getExpertReviews:
            return .get

        // Analytics
        case .getAnalyticsSummary, .getAnalyticsTrends, .getPopularTopics:
            return .get

        // Feedback
        case .getFeedbackTypes:
            return .get
        case .submitFeedback:
            return .post

        // Support
        case .getFAQs, .searchFAQs, .getFAQArticle:
            return .get
        case .createSupportTicket:
            return .post

        // Media
        case .uploadMedia:
            return .post

        // Account
        case .requestAccountDeletion:
            return .post
        case .deleteAccount:
            return .delete
        }
    }

    static func needAuthToken(url: String) -> Bool {
        !url.contains("/auth/")
    }
}
