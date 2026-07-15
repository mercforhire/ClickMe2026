//
//  BookingSummaryViewModel.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-06-27.
//  Copyright © 2026 Q42. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
final class BookingSummaryViewModel: ObservableObject {

    // MARK: Session data
    @Published var expertName: String
    @Published var expertTitle: String
    @Published var expertImageURL: String
    @Published var topic: String
    @Published var dateTime: String
    @Published var takeaways: [String]
    @Published var feedbackStars: Int
    @Published var feedbackText: String?

    init(
        expertName: String = "David Miller",
        expertTitle: String = "Machine Learning Lead",
        expertImageURL: String = "https://lh3.googleusercontent.com/aida-public/AB6AXuBnTZGMesjV2RDjvDlTqiAhGQcKvp9VwRAGKeFBQjZ2Ne3kX7qgo1NEGGhlYpLGEM-O7oYGv4ngC22GSYW5O_7nNSrkzsKF21q6DvxVUAClnY1puOrcVVRfxo7a2Q8VsPQTLluTXbfFumBJAsA8IdqCPigzs8DbXKLxdIp29xbIBxU61gPcbgR5RkgqIyJ0vmmgN_pFjG77f1XqxGlAMxxuvd1iOf-mQ1Wzc-mmg94vsBrnZYSiSZuYJ-83ZQi8i5encZyL6jSAENg",
        topic: String = "Machine Learning Consultation",
        dateTime: String = "Oct 8, 2024 • 2:00 PM - 3:00 PM",
        takeaways: [String] = BookingSummaryViewModel.sampleTakeaways,
        feedbackStars: Int = 5,
        feedbackText: String? = "David is truly an expert in his field. The way he broke down complex GAN concepts was incredible. Already seeing performance improvements in our dev environment. Highly recommended!"
    ) {
        self.expertName = expertName
        self.expertTitle = expertTitle
        self.expertImageURL = expertImageURL
        self.topic = topic
        self.dateTime = dateTime
        self.takeaways = takeaways
        self.feedbackStars = feedbackStars
        self.feedbackText = feedbackText
    }

    // MARK: Sample data

    static let sampleTakeaways: [String] = [
        "Optimized neural network architecture for real-time edge processing.",
        "Implemented data augmentation strategies to reduce training bias.",
        "Defined a roadmap for deploying the v2 model via Kubernetes.",
    ]
}
