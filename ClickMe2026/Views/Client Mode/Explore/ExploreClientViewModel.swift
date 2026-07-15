//
//  ExploreClientViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class ExploreClientViewModel: ObservableObject {

    // MARK: View state
    @Published var searchText: String
    @Published var showAllCategories: Bool
    @Published var categories: [ExpertCategory]

    // MARK: Data
    @Published var experts: [Expert]

    init(
        searchText: String = "",
        showAllCategories: Bool = false,
        categories: [ExpertCategory] = ExploreClientViewModel.defaultCategories,
        experts: [Expert] = ExploreClientViewModel.sampleExperts
    ) {
        self.searchText = searchText
        self.showAllCategories = showAllCategories
        self.categories = categories
        self.experts = experts
    }

    // MARK: Category selection

    func selectCategory(at index: Int) {
        for i in categories.indices {
            categories[i].isSelected = i == index
        }
    }

    func selectCategory(named name: String) {
        for i in categories.indices {
            categories[i].isSelected = categories[i].name == name
        }
    }

    // MARK: Sample data

    static let defaultCategories: [ExpertCategory] = [
        ExpertCategory(icon: "megaphone.fill", name: "Marketing", isSelected: false),
        ExpertCategory(icon: "paintbrush.pointed.fill", name: "Design", isSelected: true),
        ExpertCategory(icon: "chart.line.uptrend.xyaxis", name: "Finance", isSelected: false),
        ExpertCategory(icon: "brain.head.profile", name: "Coaching", isSelected: false),
        ExpertCategory(icon: "laptopcomputer", name: "Tech", isSelected: false),
    ]

    static let sampleExperts: [Expert] = [
        Expert(name: "Elena Rodriguez", title: "Senior Brand Strategist",
               tags: ["Branding", "UX Research"], rate: 120, rating: 4.9,
               imageName: "expert_elena"),
        Expert(name: "Marcus Chen", title: "Growth Hacker & Analyst",
               tags: ["SEO", "PPC"], rate: 150, rating: 5.0,
               imageName: "expert_marcus"),
        Expert(name: "Dr. Sarah Jenkins", title: "Venture Capital Consultant",
               tags: ["Fundraising", "Scaling"], rate: 200, rating: 4.8,
               imageName: "expert_sarah"),
    ]
}
