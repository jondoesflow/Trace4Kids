import Foundation
import UIKit

/// Keeps the current tracing (one picture and its placement) in the app's own folder on the device.
/// Nothing leaves the device.
final class TraceStore {
    let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    /// Application Support/Tracing.
    static func standard() -> TraceStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return TraceStore(directory: base.appendingPathComponent("Tracing", isDirectory: true))
    }

    /// A temporary folder for demo mode and tests.
    static func temporary(named name: String = "Trace4KidsDemo") -> TraceStore {
        TraceStore(directory: FileManager.default.temporaryDirectory.appendingPathComponent(name, isDirectory: true))
    }

    private var jpegURL: URL { directory.appendingPathComponent("picture.jpg") }
    private var pngURL: URL { directory.appendingPathComponent("picture.png") }
    private var settingsURL: URL { directory.appendingPathComponent("settings.json") }

    var hasSavedTracing: Bool {
        let files = FileManager.default
        return files.fileExists(atPath: jpegURL.path) || files.fileExists(atPath: pngURL.path)
    }

    /// Saves the picture as JPEG, or as PNG when it has transparency (such as a sticker).
    func savePicture(_ image: UIImage) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let keepsAlpha = Self.hasAlpha(image)
        guard let data = keepsAlpha ? image.pngData() : image.jpegData(compressionQuality: 0.9) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: keepsAlpha ? pngURL : jpegURL, options: .atomic)
        try? FileManager.default.removeItem(at: keepsAlpha ? jpegURL : pngURL)
    }

    func saveSettings(_ settings: TraceSettings) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(settings)
        try data.write(to: settingsURL, options: .atomic)
    }

    func loadPicture() -> UIImage? {
        for url in [pngURL, jpegURL] {
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                return image
            }
        }
        return nil
    }

    /// The saved placement, or the defaults when there is none or it can't be read.
    func loadSettings() -> TraceSettings {
        guard let data = try? Data(contentsOf: settingsURL),
              let settings = try? JSONDecoder().decode(TraceSettings.self, from: data) else {
            return TraceSettings()
        }
        return settings
    }

    func clear() {
        try? FileManager.default.removeItem(at: directory)
    }

    static func hasAlpha(_ image: UIImage) -> Bool {
        guard let alpha = image.cgImage?.alphaInfo else { return false }
        switch alpha {
        case .none, .noneSkipFirst, .noneSkipLast: return false
        default: return true
        }
    }
}
