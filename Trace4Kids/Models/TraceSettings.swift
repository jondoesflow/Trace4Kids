import CoreGraphics
import Foundation

/// Everything about how the picture sits on the screen, saved so a tracing can be picked up later.
///
/// The offset is stored as a fraction of the screen's width and height, and the scale is relative to
/// the picture's "fitted" size, so the placement survives a rotation or a different window size.
struct TraceSettings: Codable, Equatable {
    /// Centre of the picture from the centre of the screen, as a fraction of the screen size.
    var offsetX: Double = 0
    var offsetY: Double = 0
    /// 1 = the picture fits the screen.
    var scale: Double = 1
    /// Radians, clockwise.
    var rotation: Double = 0
    /// How solid the picture looks over the camera (0 = invisible, 1 = solid).
    var opacity: Double = 0.5
    /// Shows the picture as outlines, which are easier to follow.
    var lineArt = false
    /// Mirrors the picture left to right.
    var flipped = false
    /// White screen instead of the camera, for laying thin paper on the screen.
    var lightBox = false
    /// Pink corner brackets and edge ticks, to mark on the paper and line up again later.
    var showMarks = true
    /// Locked pictures can't be moved by accident.
    var locked = false
    /// Uses the ultra-wide camera (0.5×) where the device has one, to see more of the paper.
    var wideCamera = false

    static let scaleRange: ClosedRange<Double> = 0.15...8
    static let opacityRange: ClosedRange<Double> = 0.05...1
    /// The picture's fitted size leaves this much of the screen around it.
    static let fitMargin: CGFloat = 0.85
    /// Rotations this close to a quarter turn snap onto it.
    static let snapAngle = 6 * Double.pi / 180

    init() {}

    // MARK: Placement

    /// The size of the picture at scale 1: as big as fits in the container, keeping its shape.
    static func fittedSize(for picture: CGSize, in container: CGSize) -> CGSize {
        guard picture.width > 0, picture.height > 0, container.width > 0, container.height > 0 else { return .zero }
        let fit = min(container.width / picture.width, container.height / picture.height) * fitMargin
        return CGSize(width: picture.width * fit, height: picture.height * fit)
    }

    /// The offset in points for a container of this size.
    func offset(in container: CGSize) -> CGSize {
        CGSize(width: offsetX * container.width, height: offsetY * container.height)
    }

    /// Moves the picture by a drag in points. Its centre always stays on the screen.
    mutating func move(by translation: CGSize, in container: CGSize) {
        guard container.width > 0, container.height > 0 else { return }
        offsetX = Self.clampOffset(offsetX + translation.width / container.width)
        offsetY = Self.clampOffset(offsetY + translation.height / container.height)
    }

    mutating func zoom(by factor: Double) {
        scale = Self.clampScale(scale * factor)
    }

    mutating func rotate(by radians: Double) {
        rotation = Self.snapped(rotation + radians)
    }

    mutating func turnQuarter() {
        rotation = Self.snapped(Self.normalised(rotation + .pi / 2))
    }

    mutating func resetPlacement() {
        offsetX = 0
        offsetY = 0
        scale = 1
        rotation = 0
    }

    static func clampScale(_ value: Double) -> Double {
        min(max(value, scaleRange.lowerBound), scaleRange.upperBound)
    }

    static func clampOffset(_ value: Double) -> Double {
        min(max(value, -0.5), 0.5)
    }

    /// The angle in (-π, π].
    static func normalised(_ radians: Double) -> Double {
        var value = radians.truncatingRemainder(dividingBy: 2 * .pi)
        if value > .pi { value -= 2 * .pi }
        if value <= -.pi { value += 2 * .pi }
        return value
    }

    /// Snaps to the nearest quarter turn when close to it, so pictures end up straight.
    static func snapped(_ radians: Double) -> Double {
        let value = normalised(radians)
        let quarter = Double.pi / 2
        let nearest = (value / quarter).rounded() * quarter
        return abs(value - nearest) <= snapAngle ? normalised(nearest) : value
    }

    // MARK: Codable (missing keys fall back to defaults, so older saves still load)

    private enum CodingKeys: String, CodingKey {
        case offsetX, offsetY, scale, rotation, opacity, lineArt, flipped, lightBox, showMarks, locked, wideCamera
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = TraceSettings()
        offsetX = Self.clampOffset(try c.decodeIfPresent(Double.self, forKey: .offsetX) ?? defaults.offsetX)
        offsetY = Self.clampOffset(try c.decodeIfPresent(Double.self, forKey: .offsetY) ?? defaults.offsetY)
        scale = Self.clampScale(try c.decodeIfPresent(Double.self, forKey: .scale) ?? defaults.scale)
        rotation = Self.normalised(try c.decodeIfPresent(Double.self, forKey: .rotation) ?? defaults.rotation)
        let savedOpacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? defaults.opacity
        opacity = min(max(savedOpacity, Self.opacityRange.lowerBound), Self.opacityRange.upperBound)
        lineArt = try c.decodeIfPresent(Bool.self, forKey: .lineArt) ?? defaults.lineArt
        flipped = try c.decodeIfPresent(Bool.self, forKey: .flipped) ?? defaults.flipped
        lightBox = try c.decodeIfPresent(Bool.self, forKey: .lightBox) ?? defaults.lightBox
        showMarks = try c.decodeIfPresent(Bool.self, forKey: .showMarks) ?? defaults.showMarks
        locked = try c.decodeIfPresent(Bool.self, forKey: .locked) ?? defaults.locked
        wideCamera = try c.decodeIfPresent(Bool.self, forKey: .wideCamera) ?? defaults.wideCamera
    }
}
