import Flutter
import UIKit

/// OrientationPlugin: Manages device orientation locking and monitoring
class OrientationPlugin: NSObject {
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private let eventChannel: FlutterEventChannel
    private var eventSink: FlutterEventSink?

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        self.channel = FlutterMethodChannel(
            name: "com.cinescope/orientation",
            binaryMessenger: messenger
        )
        self.eventChannel = FlutterEventChannel(
            name: "com.cinescope/orientation/events",
            binaryMessenger: messenger
        )

        super.init()

        channel.setMethodCallHandler(handleMethodCall)
        eventChannel.setStreamHandler(self)

        // Start monitoring orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }

    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "lockLandscape":
            lockLandscape(result: result)

        case "unlockOrientation":
            unlockOrientation(result: result)

        case "getCurrentOrientation":
            getCurrentOrientation(result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func lockLandscape(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            // Force landscape orientation
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape)) { error in
                    if let error = error {
                        result(FlutterError(code: "ORIENTATION_LOCK_FAILED", message: error.localizedDescription, details: nil))
                    } else {
                        result(nil)
                    }
                }
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
                result(nil)
            }
        }
    }

    private func unlockOrientation(result: @escaping FlutterResult) {
        // Allow all orientations (for testing only)
        result(nil)
    }

    private func getCurrentOrientation(result: @escaping FlutterResult) {
        let orientation = UIDevice.current.orientation
        result(orientationToString(orientation))
    }

    @objc private func orientationDidChange() {
        let orientation = UIDevice.current.orientation
        eventSink?(orientationToString(orientation))
    }

    private func orientationToString(_ orientation: UIDeviceOrientation) -> String {
        switch orientation {
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portrait:
            return "portraitUp"
        case .portraitUpsideDown:
            return "portraitDown"
        default:
            return "unknown"
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

extension OrientationPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
