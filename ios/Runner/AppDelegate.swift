import UIKit
import Flutter
import AVFoundation

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private var videoPlayerPlugin: VideoPlayerPlugin?
    private var orientationPlugin: OrientationPlugin?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // Initialize video player plugin
        videoPlayerPlugin = VideoPlayerPlugin(messenger: controller.binaryMessenger)

        // Initialize orientation plugin
        orientationPlugin = OrientationPlugin(messenger: controller.binaryMessenger)

        // Configure audio session for optimal video playback
        configureAudioSession()

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .moviePlayback, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    override func applicationWillResignActive(_ application: UIApplication) {
        videoPlayerPlugin?.pauseAllPlayers()
    }

    override func applicationDidEnterBackground(_ application: UIApplication) {
        videoPlayerPlugin?.pauseAllPlayers()
    }
}
