//
//  ExpertProfileSectionsTests.swift
//  ClickMe2026Tests
//
//  EXPL-02: empty Expertise, Topics and Reviews sections are not drawn, and
//  the hero rating row never shows a star or 0.0 for an expert with no
//  reviews (04-UI-SPEC EM2 and Z1).
//

import Foundation
import Testing
@testable import ClickMe2026

@MainActor
@Suite("Expert profile sections")
struct ExpertProfileSectionsTests {

    // MARK: Section visibility

    @Test("Expertise is hidden with no tags and shown with one")
    func expertiseVisibility() {
        #expect(ExpertProfileSections.showsExpertise([]) == false)
        #expect(ExpertProfileSections.showsExpertise([PublicExpertTag(label: "Swift", isHighlighted: false)]))
    }

    @Test("Topics are hidden with no topics and shown with one")
    func topicsVisibility() {
        let topic = PublicTopic(title: "Intro", duration: "30 min", description: "", price: "$10", isFree: false)
        #expect(ExpertProfileSections.showsTopics([]) == false)
        #expect(ExpertProfileSections.showsTopics([topic]))
    }

    @Test("Reviews are hidden with no reviews and shown with one")
    func reviewsVisibility() {
        let review = PublicReview(reviewer: "Sam", stars: 5, body: "Great")
        #expect(ExpertProfileSections.showsReviews([]) == false)
        #expect(ExpertProfileSections.showsReviews([review]))
    }

    // MARK: Hero rating row

    @Test("before the summary loads the row shows the star, an em dash and '(— reviews)'")
    func ratingBeforeSummaryLoads() {
        let row = ExpertProfileSections.rating(summaryLoaded: false, rating: 0, reviewCount: 0)
        #expect(row == .init(showsStar: true, value: "—", label: "(— reviews)"))
    }

    @Test("zero reviews reads 'No reviews yet' with no star and no value")
    func ratingZeroReviews() {
        let row = ExpertProfileSections.rating(summaryLoaded: true, rating: 0, reviewCount: 0)
        #expect(row == .init(showsStar: false, value: nil, label: "No reviews yet"))
    }

    @Test("one review reads '(1 review)', singular")
    func ratingOneReview() {
        let row = ExpertProfileSections.rating(summaryLoaded: true, rating: 5, reviewCount: 1)
        #expect(row == .init(showsStar: true, value: "5.0", label: "(1 review)"))
    }

    @Test("many reviews read '(n reviews)' with one decimal on the rating")
    func ratingManyReviews() {
        let row = ExpertProfileSections.rating(summaryLoaded: true, rating: 4.26, reviewCount: 12)
        #expect(row == .init(showsStar: true, value: "4.3", label: "(12 reviews)"))
    }
}
