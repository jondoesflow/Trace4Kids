import SwiftUI
import UIKit

struct TraceView: View {
    @EnvironmentObject private var model: AppModel
    @StateObject private var camera = CameraController()
    @State private var showsTools = true
    @State private var showsHowTo = false
    @State private var brightnessBeforeLightBox: CGFloat?

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack {
                    background
                    if let picture = model.displayPicture {
                        TraceCanvas(picture: picture, settings: $model.settings, size: geometry.size) {
                            if model.showsMoveHint { model.showsMoveHint = false }
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 12) {
                topBar
                banner
                Spacer(minLength: 0)
                controls
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: 700)
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            if model.settings.locked { OrientationLock.set(locked: true) }
            updateCamera()
            updateBrightness()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            camera.stop()
            restoreBrightness()
        }
        .onChange(of: model.settings.lightBox) { _, _ in
            updateCamera()
            updateBrightness()
        }
        .onChange(of: model.settings.wideCamera) { _, wide in camera.setWide(wide) }
        .sheet(isPresented: $showsHowTo) { HowToView() }
    }

    // MARK: Background

    @ViewBuilder
    private var background: some View {
        if model.settings.lightBox {
            Color.white
        } else if usesCamera {
            ZStack {
                PaperBackground()
                CameraPreview(session: camera.session, status: camera.status)
                if camera.status == .denied {
                    cameraMessage("Trace4Kids needs the camera to show your paper. A grown-up can turn it on in Settings → Trace4Kids → Camera.",
                                  showsSettings: true)
                } else if camera.status == .unavailable {
                    cameraMessage("This device's camera can't be used. Try Light box instead.", showsSettings: false)
                }
            }
        } else {
            PaperBackground()
        }
    }

    private var usesCamera: Bool { !model.isDemo }

    private func cameraMessage(_ text: String, showsSettings: Bool) -> some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 14) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.accent)
                Text(text)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                if showsSettings, let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open Settings", destination: url)
                        .font(.headline)
                }
            }
            .padding(24)
            .frame(maxWidth: 420)
        }
    }

    private func updateCamera() {
        guard usesCamera else { return }
        if model.settings.lightBox {
            camera.stop()
        } else {
            camera.start(wide: model.settings.wideCamera)
        }
    }

    // Light box needs a bright screen; the brightness goes back when it's turned off or the screen closes.
    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first?.screen
    }

    private func updateBrightness() {
        guard let screen else { return }
        if model.settings.lightBox {
            if brightnessBeforeLightBox == nil { brightnessBeforeLightBox = screen.brightness }
            screen.brightness = 1
        } else {
            restoreBrightness()
        }
    }

    private func restoreBrightness() {
        if let previous = brightnessBeforeLightBox, let screen {
            screen.brightness = previous
        }
        brightnessBeforeLightBox = nil
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 12) {
            RoundButton(systemImage: "house.fill", label: "Home") { model.goHome() }
                .accessibilityIdentifier("home")
            RoundButton(systemImage: "questionmark", label: "How to trace") { showsHowTo = true }
            Spacer()
            lockButton
        }
    }

    private var lockButton: some View {
        let locked = model.settings.locked
        return Button {
            withAnimation(.spring(duration: 0.3)) { model.setLocked(!locked) }
        } label: {
            Label(locked ? "Locked" : "Lock", systemImage: locked ? "lock.fill" : "lock.open.fill")
                .font(.title3.weight(.heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .frame(minHeight: 58)
                .background(locked ? Theme.accent : Theme.purple, in: Capsule())
                .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(locked ? "Locked. Tap to move the picture again" : "Lock the picture in place")
        .accessibilityIdentifier("lock")
    }

    // MARK: Banners

    @ViewBuilder
    private var banner: some View {
        if model.isWelcomeBack {
            Card {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Welcome back! 👋")
                        .font(.title3.weight(.heavy))
                    Text("Move the picture until the pink corners sit on the marks on your paper. Then tap Lock.")
                        .font(.body.weight(.medium))
                    HStack {
                        if model.settings.locked {
                            Button("Move picture") { model.setLocked(false) }
                                .buttonStyle(.borderedProminent)
                                .tint(Theme.purple)
                        }
                        Button("It's lined up!") { model.setLocked(true) }
                            .buttonStyle(.borderedProminent)
                            .tint(Theme.accent)
                    }
                    .font(.headline)
                }
            }
            .accessibilityIdentifier("welcomeBack")
        } else if model.showsMoveHint && !model.settings.locked {
            Card {
                HStack(spacing: 12) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Theme.purple)
                    Text("Drag to move. Pinch to make it bigger or smaller. When it fits your paper, mark the pink corners and tap Lock.")
                        .font(.body.weight(.medium))
                }
            }
            .onTapGesture { model.showsMoveHint = false }
            .accessibilityIdentifier("moveHint")
        }
    }

    // MARK: Controls

    private var controls: some View {
        Card {
            VStack(spacing: 14) {
                opacitySlider

                if showsTools && !model.settings.locked {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 74), spacing: 10)], spacing: 10) {
                        ToolButton(title: model.isMakingLines ? "Wait…" : "Lines",
                                   systemImage: "scribble.variable", isOn: model.settings.lineArt) {
                            model.settings.lineArt.toggle()
                        }
                        .accessibilityIdentifier("lines")
                        ToolButton(title: "Corners", systemImage: "viewfinder", isOn: model.settings.showMarks) {
                            model.settings.showMarks.toggle()
                        }
                        .accessibilityIdentifier("corners")
                        ToolButton(title: "Flip", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                                   isOn: model.settings.flipped) {
                            model.settings.flipped.toggle()
                        }
                        ToolButton(title: "Turn", systemImage: "rotate.right") {
                            withAnimation { model.settings.turnQuarter() }
                        }
                        ToolButton(title: "Fit", systemImage: "arrow.up.left.and.arrow.down.right") {
                            withAnimation { model.settings.resetPlacement() }
                        }
                        ToolButton(title: "Light box", systemImage: "lightbulb.fill", isOn: model.settings.lightBox) {
                            model.settings.lightBox.toggle()
                        }
                        .accessibilityIdentifier("lightBox")
                        if camera.canUseWide && !model.settings.lightBox {
                            ToolButton(title: "See more", systemImage: "arrow.down.right.and.arrow.up.left",
                                       isOn: model.settings.wideCamera) {
                                model.settings.wideCamera.toggle()
                            }
                        }
                        if camera.hasTorch && !model.settings.lightBox {
                            ToolButton(title: "Torch", systemImage: "flashlight.on.fill", isOn: camera.torchOn) {
                                camera.setTorch(!camera.torchOn)
                            }
                        }
                    }
                }

                if !model.settings.locked {
                    Button {
                        withAnimation { showsTools.toggle() }
                    } label: {
                        Label(showsTools ? "Hide tools" : "Show tools",
                              systemImage: showsTools ? "chevron.down" : "chevron.up")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink.opacity(0.7))
                    }
                }
            }
        }
    }

    private var opacitySlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "eye")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .accessibilityHidden(true)
            Slider(value: $model.settings.opacity, in: TraceSettings.opacityRange)
                .tint(Theme.accent)
                .accessibilityLabel("See-through")
                .accessibilityValue("\(Int(model.settings.opacity * 100)) percent picture")
                .accessibilityIdentifier("opacity")
            Image(systemName: "photo.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.ink)
                .accessibilityHidden(true)
        }
    }
}

/// A white, rounded panel that floats over the camera.
struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .foregroundStyle(Theme.ink)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }
}
