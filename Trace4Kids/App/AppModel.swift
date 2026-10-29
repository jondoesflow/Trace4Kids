import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class AppModel: ObservableObject {
    enum Screen { case home, trace }

    @Published var screen: Screen = .home
    @Published private(set) var picture: UIImage?
    /// The outline version of the picture, made when Lines is first turned on.
    @Published private(set) var linePicture: UIImage?
    @Published private(set) var isMakingLines = false
    @Published private(set) var isOpeningPicture = false
    @Published var settings = TraceSettings() {
        didSet {
            guard settings != oldValue else { return }
            scheduleSave()
            if settings.lineArt && !oldValue.lineArt { makeLinePictureIfNeeded() }
        }
    }
    /// Shown when a saved tracing is reopened, to help line it up with the marks on the paper.
    @Published var isWelcomeBack = false
    /// Shown for a new picture until it's locked, to explain the gestures.
    @Published var showsMoveHint = false
    @Published var errorMessage: String?

    let store: TraceStore
    let isDemo: Bool
    private var saveTask: Task<Void, Never>?

    init(launch: LaunchOptions) {
        isDemo = launch.demo
        store = launch.demo ? .temporary() : .standard()
        if launch.empty { store.clear() }

        if let saved = store.loadPicture() {
            picture = saved
            settings = store.loadSettings()
        }
        if launch.startTracing, let sample = Self.samplePicture {
            start(with: sample)
        }
    }

    var hasSavedTracing: Bool { picture != nil }

    /// The picture as it should be drawn: outlines when Lines is on and ready, otherwise the photo.
    var displayPicture: UIImage? {
        settings.lineArt ? (linePicture ?? picture) : picture
    }

    /// Only bundled in Debug builds, for UI tests and screenshots.
    static var samplePicture: UIImage? {
        guard let url = Bundle.main.url(forResource: "DemoPicture", withExtension: "png"),
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: Opening and resuming

    func open(_ item: PhotosPickerItem) async {
        isOpeningPicture = true
        defer { isOpeningPicture = false }
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                errorMessage = "That picture couldn't be opened. Try another one."
                return
            }
            let image = await Task.detached(priority: .userInitiated) {
                ImageTools.downscaled(data: data)
            }.value
            guard let image else {
                errorMessage = "That picture couldn't be opened. Try another one."
                return
            }
            start(with: image)
        } catch {
            errorMessage = "That picture couldn't be opened. Try another one."
        }
    }

    func start(with image: UIImage) {
        picture = image
        linePicture = nil
        var fresh = TraceSettings()
        fresh.wideCamera = settings.wideCamera
        settings = fresh
        isWelcomeBack = false
        showsMoveHint = true
        do {
            try store.savePicture(image)
        } catch {
            errorMessage = "Trace4Kids couldn't save this picture, so it won't be here next time."
        }
        saveNow()
        screen = .trace
    }

    func resume() {
        guard picture != nil else { return }
        if settings.lineArt { makeLinePictureIfNeeded() }
        settings.showMarks = true
        isWelcomeBack = true
        showsMoveHint = false
        screen = .trace
    }

    func goHome() {
        saveNow()
        isWelcomeBack = false
        showsMoveHint = false
        if settings.locked { OrientationLock.set(locked: false) }
        screen = .home
    }

    // MARK: Lock

    func setLocked(_ locked: Bool) {
        settings.locked = locked
        OrientationLock.set(locked: locked)
        if locked {
            showsMoveHint = false
            isWelcomeBack = false
        }
    }

    // MARK: Lines

    private func makeLinePictureIfNeeded() {
        guard linePicture == nil, !isMakingLines, let picture else { return }
        isMakingLines = true
        Task {
            let lines = await Task.detached(priority: .userInitiated) {
                ImageTools.lineDrawing(of: picture)
            }.value
            // Ignore the result if a different picture was opened meanwhile.
            if self.picture === picture { self.linePicture = lines }
            self.isMakingLines = false
        }
    }

    // MARK: Saving

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard !Task.isCancelled else { return }
            saveNow()
        }
    }

    func saveNow() {
        saveTask?.cancel()
        guard picture != nil else { return }
        try? store.saveSettings(settings)
    }
}
