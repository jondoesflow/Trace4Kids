import Foundation
import Testing
import UIKit
@testable import Trace4Kids

struct TraceStoreTests {
    private func makeStore() -> TraceStore {
        let store = TraceStore.temporary(named: "Trace4KidsTests-\(UUID().uuidString)")
        store.clear()
        return store
    }

    private func image(width: Int, height: Int, opaque: Bool) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = opaque
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width / 2, height: height))
        }
    }

    @Test func savesAndLoadsPictureAndSettings() throws {
        let store = makeStore()
        defer { store.clear() }
        #expect(!store.hasSavedTracing)
        #expect(store.loadPicture() == nil)
        #expect(store.loadSettings() == TraceSettings())

        try store.savePicture(image(width: 300, height: 200, opaque: true))
        var settings = TraceSettings()
        settings.offsetY = -0.2
        settings.opacity = 0.7
        try store.saveSettings(settings)

        #expect(store.hasSavedTracing)
        let picture = try #require(store.loadPicture())
        #expect(picture.size.width * picture.scale == 300)
        #expect(store.loadSettings() == settings)
    }

    @Test func picturesWithTransparencyStayTransparent() throws {
        let store = makeStore()
        defer { store.clear() }
        let clear = image(width: 64, height: 64, opaque: false)
        #expect(TraceStore.hasAlpha(clear))
        try store.savePicture(clear)
        let loaded = try #require(store.loadPicture())
        #expect(TraceStore.hasAlpha(loaded))

        // Saving an opaque picture afterwards replaces the transparent one.
        try store.savePicture(image(width: 64, height: 64, opaque: true))
        #expect(!TraceStore.hasAlpha(try #require(store.loadPicture())))
    }

    @Test func clearRemovesEverything() throws {
        let store = makeStore()
        try store.savePicture(image(width: 10, height: 10, opaque: true))
        try store.saveSettings(TraceSettings())
        store.clear()
        #expect(!store.hasSavedTracing)
    }
}
