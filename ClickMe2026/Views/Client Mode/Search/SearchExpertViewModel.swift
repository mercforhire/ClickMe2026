//
//  SearchExpertViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-24.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class SearchExpertViewModel: ObservableObject {

    // MARK: View state
    @Published var searchText: String
    @Published var selectedCategory: String
    @Published var sortOption: String
    @Published var showSortPicker: Bool
    @Published var glowPulse: Bool

    // MARK: Data
    @Published var allExperts: [ExpertSearchResult]

    let categories: [String]
    let sortOptions: [String]

    init(
        searchText: String = "",
        selectedCategory: String = "Design",
        sortOption: String = "Most popular",
        showSortPicker: Bool = false,
        glowPulse: Bool = false,
        allExperts: [ExpertSearchResult] = SearchExpertViewModel.sampleExperts,
        categories: [String] = ["Design", "Marketing", "Fitness", "Finance", "Tech", "Legal"],
        sortOptions: [String] = ["Most popular", "Highest rated", "Newest", "Lowest price"]
    ) {
        self.searchText = searchText
        self.selectedCategory = selectedCategory
        self.sortOption = sortOption
        self.showSortPicker = showSortPicker
        self.glowPulse = glowPulse
        self.allExperts = allExperts
        self.categories = categories
        self.sortOptions = sortOptions
    }

    // MARK: Derived

    var filteredExperts: [ExpertSearchResult] {
        guard !searchText.isEmpty else { return allExperts }
        return allExperts.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.bio.localizedCaseInsensitiveContains(searchText)
        }
    }

    var showEmpty: Bool { filteredExperts.isEmpty }

    // MARK: Sample data

    static let sampleExperts: [ExpertSearchResult] = [
        ExpertSearchResult(name: "Sophia Carter", title: "Product Design Expert",
                           bio: "Specializes in user-centric design and creating intuitive...",
                           rating: 4.8, imageURL: "https://lh3.googleusercontent.com/aida-public/AB6AXuBNGXFUz9EITZoP0I4DBcFI07sjA8tNlCIrSR76s-0ILOQUmHONIn8Yp2KBQ2IYbXMt_zZ0xHTZJPxH0uAp8ynVAMCkrykEOHDlUqrE2PWSbciUg_nc-YOomp7h0MxWPtyBLVU-bL-sd9MBpMd3Rx4lD8S71qzhTd7wGXNljoREV_CApqZsm4S7omcL7oQqg0mO0htR4GFlZGp081dxaw8MX6SymSovWLGw6oOKpZkOK10cVcJmtxrmtNl0N2WbfGyAh-glPpoBV6M"),
        ExpertSearchResult(name: "Ethan Bennett", title: "Marketing Strategy Consultant",
                           bio: "Expert in brand growth and digital marketing campaigns.",
                           rating: 4.9, imageURL: "https://randomuser.me/api/portraits/men/32.jpg"),
        ExpertSearchResult(name: "Olivia Hayes", title: "Personal Fitness Trainer",
                           bio: "Helps clients achieve their fitness goals through...",
                           rating: 4.7, imageURL: "https://randomuser.me/api/portraits/women/68.jpg"),
        ExpertSearchResult(name: "Marcus Johnson", title: "Financial Planning Expert",
                           bio: "15+ years helping individuals build wealth and plan retirement.",
                           rating: 4.6, imageURL: "https://randomuser.me/api/portraits/men/55.jpg"),
    ]
}
