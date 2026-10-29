import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UIKit

enum ImageTools {
    /// Pictures are kept at up to this many pixels on the long side. That's plenty for tracing and keeps memory low.
    static let maxPixelSize = 2400

    /// Decodes a photo straight to a smaller, upright image without loading the full-size photo into memory.
    static func downscaled(data: Data, maxPixelSize: Int = maxPixelSize) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }

    /// Turns the picture into dark outlines on a see-through background, which are easier to trace.
    static func lineDrawing(of image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let input = CIImage(cgImage: cgImage)
        let longSide = max(input.extent.width, input.extent.height)
        guard longSide > 0 else { return nil }
        let shrink = min(1, 1600 / longSide)
        let small = input.transformed(by: CGAffineTransform(scaleX: shrink, y: shrink))

        let filter = CIFilter.lineOverlay()
        filter.inputImage = small
        filter.nrNoiseLevel = 0.07
        filter.nrSharpness = 0.71
        filter.edgeIntensity = 1
        filter.threshold = 0.1
        filter.contrast = 50

        guard let output = filter.outputImage?.cropped(to: small.extent),
              let result = CIContext().createCGImage(output, from: small.extent) else { return nil }
        return UIImage(cgImage: result)
    }
}
