import SwiftUI

/// The picture over the camera. Drag to move, pinch to resize and twist with two fingers to turn,
/// anywhere on the screen, so even a small picture is easy to grab. Nothing moves while locked.
struct TraceCanvas: View {
    let picture: UIImage
    @Binding var settings: TraceSettings
    let size: CGSize
    /// Called when a gesture starts, to hide the hint.
    var onTouch: () -> Void = {}

    @GestureState private var drag: CGSize = .zero
    @GestureState private var pinch: CGFloat = 1
    @GestureState private var twist: Angle = .zero

    var body: some View {
        let fitted = TraceSettings.fittedSize(for: picture.size, in: size)
        let scale = CGFloat(TraceSettings.clampScale(settings.scale * Double(pinch)))
        let width = fitted.width * scale
        let height = fitted.height * scale
        let offset = settings.offset(in: size)

        ZStack {
            Image(uiImage: picture)
                .resizable()
                .interpolation(.high)
                .frame(width: width, height: height)
                .scaleEffect(x: settings.flipped ? -1 : 1, y: 1)
                .opacity(settings.opacity)
                .accessibilityHidden(true)

            if settings.showMarks {
                CornerMarks()
                    .frame(width: width, height: height)
            }
        }
        .rotationEffect(.radians(settings.rotation + twist.radians))
        .offset(x: offset.width + drag.width, y: offset.height + drag.height)
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(moveGesture, including: settings.locked ? .none : .all)
        .accessibilityElement()
        .accessibilityLabel("Your picture")
        .accessibilityIdentifier("tracePicture")
    }

    private var moveGesture: some Gesture {
        let dragGesture = DragGesture()
            .updating($drag) { value, state, _ in state = value.translation }
            .onChanged { _ in onTouch() }
            .onEnded { value in settings.move(by: value.translation, in: size) }
        let pinchGesture = MagnifyGesture()
            .updating($pinch) { value, state, _ in state = value.magnification }
            .onEnded { value in settings.zoom(by: Double(value.magnification)) }
        let twistGesture = RotateGesture()
            .updating($twist) { value, state, _ in state = value.rotation }
            .onEnded { value in settings.rotate(by: value.rotation.radians) }
        return dragGesture.simultaneously(with: pinchGesture).simultaneously(with: twistGesture)
    }
}

/// Pink brackets at the picture's corners and ticks at the middle of each edge, with a dashed border.
/// Mark these spots on the paper, and next time line the picture up with the marks.
struct CornerMarks: View {
    var body: some View {
        GeometryReader { geometry in
            let length = min(40, geometry.size.width / 4, geometry.size.height / 4)
            ZStack {
                Rectangle()
                    .strokeBorder(Theme.mark.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                EdgeMarks(length: length)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                EdgeMarks(length: length)
                    .stroke(Theme.mark, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct EdgeMarks: Shape {
    var length: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let l = length
        let tick = length / 2
        // Corners
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + l))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + l, y: rect.minY))

        path.move(to: CGPoint(x: rect.maxX - l, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + l))

        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - l))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - l, y: rect.maxY))

        path.move(to: CGPoint(x: rect.minX + l, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - l))

        // Ticks across the middle of each edge
        path.move(to: CGPoint(x: rect.midX, y: rect.minY - tick))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY + tick))
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY - tick))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY + tick))
        path.move(to: CGPoint(x: rect.minX - tick, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX + tick, y: rect.midY))
        path.move(to: CGPoint(x: rect.maxX - tick, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX + tick, y: rect.midY))
        return path
    }
}

/// Stands in for the camera on the simulator, in demo mode, or when the camera can't be used.
struct PaperBackground: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.98, green: 0.97, blue: 0.93)
                Path { path in
                    var y: CGFloat = 40
                    while y < geometry.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                        y += 34
                    }
                }
                .stroke(Color.blue.opacity(0.12), lineWidth: 1)
            }
        }
        .accessibilityHidden(true)
    }
}
