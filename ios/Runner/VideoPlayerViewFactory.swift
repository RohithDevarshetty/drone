import Flutter
import UIKit
import AVFoundation

/// Platform view factory for video player views
class VideoPlayerViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var plugin: VideoPlayerPlugin?

    init(plugin: VideoPlayerPlugin) {
        self.plugin = plugin
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return VideoPlayerPlatformView(
            frame: frame,
            viewId: viewId,
            args: args,
            plugin: plugin
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Platform view for rendering AVPlayer
class VideoPlayerPlatformView: NSObject, FlutterPlatformView {
    private let videoView: UIView
    private var playerLayer: AVPlayerLayer?

    init(
        frame: CGRect,
        viewId: Int,
        args: Any?,
        plugin: VideoPlayerPlugin?
    ) {
        videoView = UIView(frame: frame)
        videoView.backgroundColor = .black

        super.init()

        guard let arguments = args as? [String: Any],
              let playerId = arguments["playerId"] as? Int,
              let player = plugin?.getPlayer(playerId: playerId) else {
            return
        }

        // Create and configure player layer
        playerLayer = player.getPlayerLayer()
        playerLayer?.frame = videoView.bounds

        // Ensure hardware acceleration is used
        playerLayer?.drawsAsynchronously = true

        videoView.layer.addSublayer(playerLayer!)

        // Auto-play if requested
        if let isPlaying = arguments["isPlaying"] as? Bool, isPlaying {
            player.play()
        }
    }

    func view() -> UIView {
        return videoView
    }

    deinit {
        playerLayer?.removeFromSuperlayer()
    }
}
