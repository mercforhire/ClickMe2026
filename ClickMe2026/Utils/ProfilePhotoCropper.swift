//
//  ProfilePhotoCropper.swift
//  ClickMe2026
//
//  Created by Leon Chen on 2026-11-13.
//  Copyright © 2026 Uptrend Investments Inc. All rights reserved.
//

import UIKit

/// Renders the square the signup photo preview shows (SIGN-05).
///
/// `ProfileAvatarRing` draws the picked image `scaledToFill`, scales it by
/// `1 + zoom` and masks it with a centred circle, with no panning. The visible
/// region is therefore the centred square of side `min(width, height) / (1 + zoom)`
/// of the upright image. Save used to upload the whole original instead, so the
/// public avatar did not match what the user framed.
///
/// The crop is a fresh render, so the original file's metadata (EXIF, GPS
/// location) is not carried into the upload.
enum ProfilePhotoCropper {

    /// Longest side of the uploaded square, in pixels. Keeps the JPEG far under
    /// the 5 MB limit of `POST /user/profile/avatar`.
    static let maxSide: CGFloat = 1024

    /// JPEG quality of the uploaded avatar.
    static let jpegQuality: CGFloat = 0.85

    /// JPEG bytes of the centred square the preview shows at `zoom`.
    /// - Parameters:
    ///   - image: The picked photo. Its orientation is applied before cropping.
    ///   - zoom: The slider value; the preview scales by `1 + zoom`. Clamped to `0...1`.
    ///   - maxSide: Cap on the output side in pixels; larger crops are scaled down.
    /// - Returns: `nil` when the image has no pixel data or cannot be rendered.
    static func squareCrop(
        _ image: UIImage,
        zoom: CGFloat,
        maxSide: CGFloat = ProfilePhotoCropper.maxSide
    ) -> Data? {
        let pixelWidth = (image.size.width * image.scale).rounded()
        let pixelHeight = (image.size.height * image.scale).rounded()
        guard pixelWidth >= 1, pixelHeight >= 1, maxSide >= 1 else { return nil }

        // Bake the orientation in: draw the upright image at pixel size.
        let uprightFormat = UIGraphicsImageRendererFormat()
        uprightFormat.scale = 1
        uprightFormat.opaque = true
        let upright = UIGraphicsImageRenderer(
            size: CGSize(width: pixelWidth, height: pixelHeight),
            format: uprightFormat
        ).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
            image.draw(in: CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        }
        guard let uprightCG = upright.cgImage else { return nil }

        // Integer square, centred. Rounding the side and flooring the origin
        // keeps the rectangle square and the result the same on every call.
        let clampedZoom = min(max(zoom, 0), 1)
        let width = CGFloat(uprightCG.width)
        let height = CGFloat(uprightCG.height)
        let side = max(1, (min(width, height) / (1 + clampedZoom)).rounded())
        let cropRect = CGRect(
            x: ((width - side) / 2).rounded(.down),
            y: ((height - side) / 2).rounded(.down),
            width: side,
            height: side
        )
        guard let cropped = uprightCG.cropping(to: cropRect) else { return nil }

        let outputSide = min(maxSide.rounded(.down), CGFloat(cropped.width))
        let outputFormat = UIGraphicsImageRendererFormat()
        outputFormat.scale = 1
        outputFormat.opaque = true
        let output = UIGraphicsImageRenderer(
            size: CGSize(width: outputSide, height: outputSide),
            format: outputFormat
        ).image { _ in
            UIImage(cgImage: cropped).draw(in: CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
        }
        return output.jpegData(compressionQuality: jpegQuality)
    }
}
