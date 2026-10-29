import CoreGraphics
import Foundation
import Testing
@testable import Trace4Kids

struct TraceSettingsTests {
    @Test func fittedSizeKeepsShapeAndLeavesMargin() {
        let size = TraceSettings.fittedSize(for: CGSize(width: 2000, height: 1000), in: CGSize(width: 400, height: 800))
        #expect(abs(size.width - 400 * TraceSettings.fitMargin) < 0.001)
        #expect(abs(size.height - 200 * TraceSettings.fitMargin) < 0.001)
        #expect(TraceSettings.fittedSize(for: .zero, in: CGSize(width: 10, height: 10)) == .zero)
    }

    @Test func offsetIsStoredAsFractionOfScreen() {
        var settings = TraceSettings()
        settings.move(by: CGSize(width: 100, height: -50), in: CGSize(width: 400, height: 1000))
        #expect(abs(settings.offsetX - 0.25) < 0.0001)
        #expect(abs(settings.offsetY + 0.05) < 0.0001)
        // The same placement on a rotated screen lands in the same relative spot.
        let rotated = settings.offset(in: CGSize(width: 1000, height: 400))
        #expect(abs(rotated.width - 250) < 0.001)
        #expect(abs(rotated.height + 20) < 0.001)
    }

    @Test func pictureCentreStaysOnScreen() {
        var settings = TraceSettings()
        settings.move(by: CGSize(width: 10_000, height: -10_000), in: CGSize(width: 400, height: 800))
        #expect(settings.offsetX == 0.5)
        #expect(settings.offsetY == -0.5)
    }

    @Test func zoomIsClamped() {
        var settings = TraceSettings()
        settings.zoom(by: 100)
        #expect(settings.scale == TraceSettings.scaleRange.upperBound)
        settings.zoom(by: 0.000_1)
        #expect(settings.scale == TraceSettings.scaleRange.lowerBound)
    }

    @Test func rotationSnapsToQuarterTurns() {
        let fiveDegrees = 5 * Double.pi / 180
        #expect(TraceSettings.snapped(Double.pi / 2 + fiveDegrees) == Double.pi / 2)
        #expect(TraceSettings.snapped(fiveDegrees) == 0)
        let twenty = 20 * Double.pi / 180
        #expect(abs(TraceSettings.snapped(twenty) - twenty) < 0.000_001)

        var settings = TraceSettings()
        for _ in 0..<4 { settings.turnQuarter() }
        #expect(abs(settings.rotation) < 0.000_001)
    }

    @Test func resetPutsPictureBackInTheMiddle() {
        var settings = TraceSettings()
        settings.move(by: CGSize(width: 50, height: 50), in: CGSize(width: 100, height: 100))
        settings.zoom(by: 2)
        settings.rotate(by: 1)
        settings.opacity = 0.8
        settings.resetPlacement()
        #expect(settings.offsetX == 0 && settings.offsetY == 0 && settings.scale == 1 && settings.rotation == 0)
        #expect(settings.opacity == 0.8)
    }

    @Test func codableRoundTrip() throws {
        var settings = TraceSettings()
        settings.offsetX = 0.1
        settings.scale = 2.5
        settings.lineArt = true
        settings.locked = true
        let data = try JSONEncoder().encode(settings)
        #expect(try JSONDecoder().decode(TraceSettings.self, from: data) == settings)
    }

    @Test func missingAndBadValuesFallBackSafely() throws {
        let json = #"{"scale": 99, "opacity": -3, "offsetX": 4}"#.data(using: .utf8)!
        let settings = try JSONDecoder().decode(TraceSettings.self, from: json)
        #expect(settings.scale == TraceSettings.scaleRange.upperBound)
        #expect(settings.opacity == TraceSettings.opacityRange.lowerBound)
        #expect(settings.offsetX == 0.5)
        #expect(settings.showMarks == true)
        #expect(settings.locked == false)
    }
}
