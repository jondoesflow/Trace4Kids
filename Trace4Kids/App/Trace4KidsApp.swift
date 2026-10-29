import SwiftUI
import UIKit

@main
struct Trace4KidsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = AppModel(launch: .current)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(model)
                .fontDesign(.rounded)
                .onChange(of: scenePhase) { _, phase in
                    if phase != .active { model.saveNow() }
                }
        }
    }
}

/// Launch arguments used by UI tests and screenshots.
struct LaunchOptions {
    /// `-TraceDemo`: the sample picture is available, a paper background stands in for the camera,
    /// and the tracing is kept in a temporary folder.
    var demo = false
    /// `-TraceEmpty`: with `-TraceDemo`, starts with nothing saved.
    var empty = false
    /// `-TraceStart`: with `-TraceDemo`, opens the sample picture straight away.
    var startTracing = false

    static var current: LaunchOptions {
        let arguments = ProcessInfo.processInfo.arguments
        var options = LaunchOptions()
        options.demo = arguments.contains("-TraceDemo")
        options.empty = options.demo && arguments.contains("-TraceEmpty")
        options.startTracing = options.demo && arguments.contains("-TraceStart")
        return options
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.mask
    }
}

/// Stops the screen rotating while a tracing is locked, so a device lying flat on a stand
/// doesn't flip the picture around. iPad windows that share the screen may ignore this.
@MainActor
enum OrientationLock {
    static var mask: UIInterfaceOrientationMask = defaultMask

    private static var defaultMask: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
    }

    static func set(locked: Bool) {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        if locked, let scene {
            switch scene.interfaceOrientation {
            case .portrait: mask = .portrait
            case .portraitUpsideDown: mask = .portraitUpsideDown
            case .landscapeLeft: mask = .landscapeLeft
            case .landscapeRight: mask = .landscapeRight
            default: mask = defaultMask
            }
        } else {
            mask = defaultMask
        }
        scene?.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
