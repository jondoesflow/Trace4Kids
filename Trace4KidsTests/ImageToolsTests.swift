import Foundation
import Testing
import UIKit
@testable import Trace4Kids

struct ImageToolsTests {
    private func pngData(width: Int, height: Int) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            UIColor.black.setFill()
            context.fill(CGRect(x: width / 4, y: height / 4, width: width / 2, height: height / 2))
        }
        return image.pngData()!
    }

    @Test func largePhotosAreShrunk() throws {
        let image = try #require(ImageTools.downscaled(data: pngData(width: 4000, height: 3000)))
        let cg = try #require(image.cgImage)
        #expect(max(cg.width, cg.height) == ImageTools.maxPixelSize)
        #expect(cg.width > cg.height)
    }

    @Test func smallPhotosAreNotEnlarged() throws {
        let image = try #require(ImageTools.downscaled(data: pngData(width: 300, height: 200)))
        let cg = try #require(image.cgImage)
        #expect(cg.width <= 300 && cg.height <= 200)
    }

    @Test func notAPictureGivesNil() {
        #expect(ImageTools.downscaled(data: Data("hello".utf8)) == nil)
    }

    @Test func lineDrawingHasSeeThroughBackground() throws {
        let source = try #require(UIImage(data: pngData(width: 400, height: 300)))
        let lines = try #require(ImageTools.lineDrawing(of: source))
        #expect(lines.size.width > 0)
        #expect(TraceStore.hasAlpha(lines))
    }
}
