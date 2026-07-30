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
    case signup
    case resendVerificationEmail
    case checkEmailVerified
    case verifyEmailCode
    case forgotPassword
    case resetPassword

    // MARK: Me
    case getMe

    // MARK: Expert Profile
    case getExpertProfile
    case setupExpertProfile
    case updateExpertProfile

    // MARK: Meta
    case getExpertiseTags
    case getCurrencies
    case getLanguages
    case getAllCategories

    // MARK: User Profile
    case getUserProfile
    case updateUserProfile
    case uploadAvatar
    case deleteAvatar
    case updatePassword

    // MARK: Discovery
    case getClientHome
    case searchExperts
    case getDiscoveryFeed
    case getRandomExperts
    case recordInteraction
    case getExpertDetails
    case getExpertTopics
    case getExpert

    // MARK: Favorites
    case getClientFavorites
    case addFavorite
    case removeFavorite

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
    case getClientBookingDetail
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

    // MARK: Expert Topics
    case getMyTopics
    case createMyTopic
    case updateMyTopic
    case deleteMyTopic

    // MARK: Expert Clients
    case getClientProfile

    // MARK: Expert Payouts + Stripe Connect
    case getWeeklyEarnings
    case getPayoutSummary
    case startConnectOnboarding

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
    case getNotificationPreferences
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

    // MARK: Payment Methods (client-side saved cards)
    case getPaymentMethods
    case createPaymentMethodSetupIntent
    case deletePaymentMethod
    case setDefaultPaymentMethod

    // MARK: Media
    case uploadMedia

    // MARK: Account
    case requestAccountDeletion
    case deleteAccount

    var path: String {
        switch self {
        // Auth
        case .login:                   return "/auth/login"
        case .signup:                  return "/auth/signup"
        case .resendVerificationEmail: return "/auth/email/resend"
        case .checkEmailVerified:      return "/auth/email/status"
        case .verifyEmailCode:         return "/auth/email/verify"
        case .forgotPassword:          return "/auth/password/forgot"
        case .resetPassword:           return "/auth/password/reset"

        // Me
        case .getMe: return "/me"

        // Expert Profile
        case .getExpertProfile:    return "/expert/profile"
        case .setupExpertProfile:  return "/expert/profile/setup"
        case .updateExpertProfile: return "/expert/profile"

        // Meta
        case .getExpertiseTags: return "/meta/expertise-tags"
        case .getCurrencies:    return "/meta/currencies"
        case .getLanguages:     return "/meta/languages"
        case .getAllCategories: return "/categories"

        // User Profile
        case .getUserProfile:    return "/user/profile"
        case .updateUserProfile: return "/user/profile"
        case .uploadAvatar,
             .deleteAvatar:      return "/user/profile/avatar"
        case .updatePassword:    return "/user/password"

        // Discovery
        case .getClientHome:     return "/client/home"
        case .searchExperts:     return "/experts/search"
        case .getDiscoveryFeed:  return "/discovery/feed"
        case .getRandomExperts:  return "/discovery/random"
        case .recordInteraction: return "/discovery/interact"
        case .getExpertDetails:  return "/experts/:id/details"
        case .getExpertTopics:   return "/experts/:id/topics"
        case .getExpert:         return "/experts/:id"

        // Favorites
        case .getClientFavorites: return "/client/favorites"
        case .addFavorite,
             .removeFavorite:    return "/client/favorites/:id"

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
        case .getClientBookingDetail:  return "/client/bookings/:id"
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

        // Expert Topics
        case .getMyTopics,
             .createMyTopic:           return "/expert/topics"
        case .updateMyTopic,
             .deleteMyTopic:           return "/expert/topics/:id"

        // Expert Clients
        case .getClientProfile:        return "/expert/clients/:id"

        // Expert Payouts + Stripe Connect
        case .getWeeklyEarnings:       return "/expert/earnings/weekly"
        case .getPayoutSummary:        return "/expert/payouts/summary"
        case .startConnectOnboarding:  return "/expert/connect/onboard"

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
        case .getNotificationPreferences:    return "/notifications/preferences"
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

        // Payment Methods
        case .getPaymentMethods:               return "/me/payment-methods"
        case .createPaymentMethodSetupIntent:  return "/me/payment-methods/setup-intent"
        case .deletePaymentMethod:             return "/me/payment-methods/:id"
        case .setDefaultPaymentMethod:         return "/me/payment-methods/:id/default"

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
        case .login, .signup, .resendVerificationEmail, .forgotPassword, .resetPassword, .verifyEmailCode:
            return .post
        case .checkEmailVerified:
            return .get

        // Me
        case .getMe:
            return .get

        // Expert Profile
        case .getExpertProfile:
            return .get
        case .setupExpertProfile, .updateExpertProfile:
            return .patch

        // Meta
        case .getExpertiseTags, .getCurrencies, .getLanguages, .getAllCategories:
            return .get

        // User Profile
        case .getUserProfile:
            return .get
        case .updateUserProfile, .updatePassword:
            return .patch
        case .uploadAvatar:
            return .post
        case .deleteAvatar:
            return .delete

        // Discovery
        case .getClientHome, .searchExperts, .getDiscoveryFeed, .getRandomExperts,
             .getExpertDetails, .getExpertTopics, .getExpert:
            return .get
        case .recordInteraction:
            return .post

        // Favorites
        case .getClientFavorites:
            return .get
        case .addFavorite:
            return .put
        case .removeFavorite:
            return .delete

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
        case .getClientBookings, .getClientBookingDetail, .getExpertBookings,
             .getExpertBookingDetails, .getExpertBookingSummary,
             .getBookingRequests, .getBookingRequest, .getBookingNote:
            return .get
        case .rescheduleClientBooking, .updateBookingStatus, .rescheduleExpertBooking:
            return .patch
        case .updateBookingTakeaways:
            return .put

        // Expert Topics
        case .getMyTopics:    return .get
        case .createMyTopic:  return .post
        case .updateMyTopic:  return .patch
        case .deleteMyTopic:  return .delete

        // Expert Clients
        case .getClientProfile:
            return .get

        // Expert Payouts + Stripe Connect
        case .getWeeklyEarnings,
             .getPayoutSummary:
            return .get
        case .startConnectOnboarding:
            return .post

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
        case .getNotifications, .getNotificationPreferences:
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

        // Payment Methods
        case .getPaymentMethods:
            return .get
        case .createPaymentMethodSetupIntent:
            return .post
        case .deletePaymentMethod:
            return .delete
        case .setDefaultPaymentMethod:
            return .patch

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

    /// Only the credential-establishing endpoints are truly unauthenticated.
    /// The verification endpoints (`/auth/email/*`) live under `/auth/` for
    /// path taxonomy but are authorised by the bearer issued at signup.
    private static let publicPaths: Set<String> = [
        "/auth/login",
        "/auth/signup",
        "/auth/password/forgot",
        "/auth/password/reset",
    ]

    static func needAuthToken(url: String) -> Bool {
        !publicPaths.contains { url.hasSuffix($0) }
    }
}
