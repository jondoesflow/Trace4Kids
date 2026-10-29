import AVFoundation
import SwiftUI

/// Runs the back camera for the live view behind the picture. Nothing is recorded: the session has
/// no outputs, only the on-screen preview.
@MainActor
final class CameraController: ObservableObject {
    enum Status: Equatable { case starting, running, denied, unavailable }

    @Published private(set) var status: Status = .starting
    /// The device has an ultra-wide camera, so a 0.5× view is possible.
    @Published private(set) var canUseWide = false
    @Published private(set) var hasTorch = false
    @Published private(set) var torchOn = false

    let session = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.jondoesflow.trace4kids.camera")
    private var device: AVCaptureDevice?

    func start(wide: Bool) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun(wide: wide)
        case .notDetermined:
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                if granted { configureAndRun(wide: wide) } else { status = .denied }
            }
        default:
            status = .denied
        }
    }

    func stop() {
        torchOn = false
        let session = session
        queue.async {
            if session.isRunning { session.stopRunning() }
        }
    }

    func setWide(_ wide: Bool) {
        guard let device else { return }
        let target: CGFloat
        if canUseWide {
            // On a virtual camera, zoom 1 is the ultra-wide lens and the first switch-over is the normal 1× lens.
            let normal = device.virtualDeviceSwitchOverVideoZoomFactors.first.map { CGFloat(truncating: $0) } ?? 1
            target = wide ? device.minAvailableVideoZoomFactor : normal
        } else {
            target = 1
        }
        do {
            try device.lockForConfiguration()
            device.videoZoomFactor = min(max(target, device.minAvailableVideoZoomFactor), device.maxAvailableVideoZoomFactor)
            device.unlockForConfiguration()
        } catch {}
    }

    func setTorch(_ on: Bool) {
        guard let device, device.hasTorch, status == .running else { return }
        do {
            try device.lockForConfiguration()
            if on {
                try device.setTorchModeOn(level: 0.6)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
            torchOn = on
        } catch {
            torchOn = false
        }
    }

    private func configureAndRun(wide: Bool) {
        if device == nil {
            guard let camera = Self.backCamera(),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                status = .unavailable
                return
            }
            session.beginConfiguration()
            session.sessionPreset = .high
            if session.canAddInput(input) { session.addInput(input) }
            session.commitConfiguration()
            device = camera
            canUseWide = camera.isVirtualDevice
                && camera.constituentDevices.contains { $0.deviceType == .builtInUltraWideCamera }
            hasTorch = camera.hasTorch
        }
        setWide(wide)
        let session = session
        queue.async {
            if !session.isRunning { session.startRunning() }
        }
        status = .running
    }

    /// Prefers cameras that include the ultra-wide lens, so 0.5× is available.
    private static func backCamera() -> AVCaptureDevice? {
        let preferred: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera, .builtInDualWideCamera, .builtInDualCamera, .builtInWideAngleCamera,
        ]
        for type in preferred {
            if let device = AVCaptureDevice.default(type, for: .video, position: .back) { return device }
        }
        return nil
    }
}

/// The live camera picture, filling the screen and kept upright as the screen rotates.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    /// Passed in so the view refreshes its rotation once the camera starts.
    let status: CameraController.Status

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        view.updateRotation()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var previewLayer: AVCaptureVideoPreviewLayer {
            // layerClass guarantees the type.
            layer as! AVCaptureVideoPreviewLayer
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateRotation()
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            updateRotation()
        }

        func updateRotation() {
            guard let connection = previewLayer.connection,
                  let orientation = window?.windowScene?.interfaceOrientation else { return }
            let angle: CGFloat
            switch orientation {
            case .portrait: angle = 90
            case .portraitUpsideDown: angle = 270
            case .landscapeLeft: angle = 180
            case .landscapeRight: angle = 0
            default: angle = 90
            }
            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}
