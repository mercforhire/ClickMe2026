//
//  SignupProfilePhotoSaveTests.swift
//  ClickMe2026Tests
//
//  SIGN-05: Save uploads the cropped square once; an image that cannot be
//  rendered uploads nothing and shows an error; a downloaded avatar is
//  display-only, so Save with no newly picked photo sends no request.
//

import Foundation
import Testing
import UIKit
@testable import ClickMe2026

@MainActor
@Suite("Signup profile photo save", .serialized)
struct SignupProfilePhotoSaveTests {

    // MARK: - Fixtures

    private nonisolated static let uploadedUrl = "https://cdn.test.clickme.local/avatars/new.jpg"

    /// A client whose every request succeeds with the avatar upload body.
    private static func makeAPI() -> ClickMeAPI {
        APITestFactory.make { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            let body = "{\"status\":\"success\",\"data\":{\"avatar_url\":\"\(uploadedUrl)\"}}"
            return (response, Data(body.utf8))
        }
    }

    private static func avatarRequestCount() -> Int {
        MockURLProtocol.recordedRequests.filter { $0.url?.path.hasSuffix("/user/profile/avatar") == true }.count
    }

    private static func solidImage(side: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }

    // MARK: - Tests

    @Test("Save with a picked photo uploads once and stores the returned URL")
    func saveUploadsOnce() async {
        let accumulator = SignupAccumulator()
        let viewModel = SignupProfilePhotoViewModel(accumulator: accumulator, api: Self.makeAPI())
        viewModel.usePickedImage(Self.solidImage(side: 600))
        #expect(viewModel.canZoom)

        await viewModel.save()

        #expect(Self.avatarRequestCount() == 1)
        #expect(viewModel.isSaved)
        #expect(viewModel.saveError == nil)
        #expect(accumulator.avatarUrl == Self.uploadedUrl)
    }

    @Test("An image with no pixels sets an error and sends no request")
    func emptyImageUploadsNothing() async {
        let accumulator = SignupAccumulator()
        let viewModel = SignupProfilePhotoViewModel(accumulator: accumulator, api: Self.makeAPI())
        viewModel.usePickedImage(UIImage())

        await viewModel.save()

        #expect(Self.avatarRequestCount() == 0)
        #expect(viewModel.saveError != nil)
        #expect(!viewModel.isSaved)
        #expect(accumulator.avatarUrl == nil)
    }

    @Test("A downloaded avatar is not zoomable and Save sends no request")
    func hydratedAvatarUploadsNothing() async {
        let accumulator = SignupAccumulator()
        accumulator.avatarUrl = "https://cdn.test.clickme.local/avatars/existing.jpg"
        let viewModel = SignupProfilePhotoViewModel(accumulator: accumulator, api: Self.makeAPI())

        #expect(!viewModel.canZoom)
        await viewModel.save()

        #expect(Self.avatarRequestCount() == 0)
        #expect(viewModel.isSaved)
        #expect(accumulator.avatarUrl == "https://cdn.test.clickme.local/avatars/existing.jpg")
    }

    @Test("Picking a photo resets the zoom and enables the slider")
    func pickingEnablesZoom() {
        let viewModel = SignupProfilePhotoViewModel(accumulator: SignupAccumulator(), api: Self.makeAPI())
        viewModel.zoomScale = 0.9
        #expect(!viewModel.canZoom)

        viewModel.usePickedImage(Self.solidImage(side: 100))

        #expect(viewModel.canZoom)
        #expect(viewModel.zoomScale == 0.5)
        #expect(viewModel.hasPhoto)
    }
}
