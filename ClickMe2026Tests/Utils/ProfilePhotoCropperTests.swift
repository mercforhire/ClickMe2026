//
//  ProfilePhotoCropperTests.swift
//  ClickMe2026Tests
//
//  SIGN-05: Save uploads the square the preview circle shows, not the whole
//  original. The preview scales the filled image by `1 + zoom` about its
//  centre, so the visible square has side `min(width, height) / (1 + zoom)`.
//

import CoreGraphics
import ImageIO
import Testing
import UIKit
@testable import ClickMe2026

@MainActor
@Suite("Profile photo cropper")
struct ProfilePhotoCropperTests {

    // MARK: - Helpers

    /// A scale-1 image of the given pixel size filled with `draw`.
    private static func makeImage(
        width: Int,
        height: Int,
        draw: (CGContext) -> Void
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(
            size: CGSize(width: width, height: height),
            format: format
        ).image { context in
            draw(context.cgContext)
        }
    }

    private static func solidImage(width: Int, height: Int, color: UIColor = .red) -> UIImage {
        makeImage(width: width, height: height) { context in
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    /// Pixel size of decoded JPEG bytes.
    private static func pixelSize(of data: Data) -> (width: Int, height: Int)? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        return (cgImage.width, cgImage.height)
    }

    /// RGB of the pixel at (x, y), measured from the top-left corner.
    private static func pixel(in data: Data, x: Int, y: Int) -> (r: Int, g: Int, b: Int)? {
        guard let cgImage = UIImage(data: data)?.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn, x >= 0, x < width, y >= 0, y < height else { return nil }
        let offset = (y * width + x) * 4
        return (Int(bytes[offset]), Int(bytes[offset + 1]), Int(bytes[offset + 2]))
    }

    private static let tolerance = 40

    private static func isClose(_ actual: (r: Int, g: Int, b: Int)?, _ expected: (r: Int, g: Int, b: Int)) -> Bool {
        guard let actual else { return false }
        return abs(actual.r - expected.r) <= tolerance
            && abs(actual.g - expected.g) <= tolerance
            && abs(actual.b - expected.b) <= tolerance
    }

    // MARK: - Size

    @Test("A 2000x1000 photo at zoom 0 uploads the 1000x1000 centre")
    func landscapeZeroZoom() throws {
        let data = try #require(ProfilePhotoCropper.squareCrop(Self.solidImage(width: 2000, height: 1000), zoom: 0))
        let size = try #require(Self.pixelSize(of: data))
        #expect(size.width == 1000)
        #expect(size.height == 1000)
    }

    @Test("A 2000x1000 photo at zoom 1 uploads the 500x500 centre")
    func landscapeFullZoom() throws {
        let data = try #require(ProfilePhotoCropper.squareCrop(Self.solidImage(width: 2000, height: 1000), zoom: 1))
        let size = try #require(Self.pixelSize(of: data))
        #expect(size.width == 500)
        #expect(size.height == 500)
    }

    @Test("A square photo at zoom 0 uploads the whole image; at zoom 0.5 a 1/1.5 square")
    func squareAdjacency() throws {
        let image = Self.solidImage(width: 600, height: 600)
        let whole = try #require(ProfilePhotoCropper.squareCrop(image, zoom: 0))
        let wholeSize = try #require(Self.pixelSize(of: whole))
        #expect(wholeSize.width == 600)
        #expect(wholeSize.height == 600)

        let zoomed = try #require(ProfilePhotoCropper.squareCrop(image, zoom: 0.5))
        let zoomedSize = try #require(Self.pixelSize(of: zoomed))
        #expect(zoomedSize.width == 400)
        #expect(zoomedSize.height == 400)
    }

    @Test("A large photo is scaled down to at most 1024 px")
    func largePhotoIsCapped() throws {
        let data = try #require(ProfilePhotoCropper.squareCrop(Self.solidImage(width: 4000, height: 3000), zoom: 0))
        let size = try #require(Self.pixelSize(of: data))
        #expect(size.width == 1024)
        #expect(size.height == 1024)
    }

    @Test("Zoom outside 0...1 is clamped")
    func zoomIsClamped() throws {
        let image = Self.solidImage(width: 2000, height: 1000)
        let below = try #require(ProfilePhotoCropper.squareCrop(image, zoom: -1))
        let belowSize = try #require(Self.pixelSize(of: below))
        #expect(belowSize.width == 1000)

        let above = try #require(ProfilePhotoCropper.squareCrop(image, zoom: 2))
        let aboveSize = try #require(Self.pixelSize(of: above))
        #expect(aboveSize.width == 500)
    }

    // MARK: - Content

    @Test("Zoom 1 keeps the centre of the photo and drops its corners")
    func zoomedOutputShowsTheCentre() throws {
        // Red 300x300 with a centred 100x100 green square; at zoom 1 the crop
        // is exactly that 150x150 centre, so the middle is green and a corner
        // of the square still sees red.
        let image = Self.makeImage(width: 300, height: 300) { context in
            context.setFillColor(UIColor.red.cgColor)
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 300))
            context.setFillColor(UIColor.green.cgColor)
            context.fill(CGRect(x: 100, y: 100, width: 100, height: 100))
        }
        let data = try #require(ProfilePhotoCropper.squareCrop(image, zoom: 1))
        let size = try #require(Self.pixelSize(of: data))
        #expect(size.width == 150)
        #expect(Self.isClose(Self.pixel(in: data, x: 75, y: 75), (0, 255, 0)))
        #expect(Self.isClose(Self.pixel(in: data, x: 2, y: 2), (255, 0, 0)))
    }
}
