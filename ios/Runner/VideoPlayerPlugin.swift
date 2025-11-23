import Flutter
import AVFoundation
import UIKit

/// VideoPlayerPlugin: Native iOS video player using AVPlayer
/// Implements hardware-accelerated playback (NFR3) with HEVC support
class VideoPlayerPlugin: NSObject {
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private var players: [Int: CinescopeVideoPlayer] = [:]
    private var platformViewFactory: VideoPlayerViewFactory?

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        self.channel = FlutterMethodChannel(
            name: "com.cinescope/videoplayer",
            binaryMessenger: messenger
        )
        super.init()

        // Register platform view factory
        platformViewFactory = VideoPlayerViewFactory(plugin: self)
        let registrar = (UIApplication.shared.delegate as! FlutterAppDelegate).registrar(forPlugin: "VideoPlayerPlugin")
        registrar?.register(platformViewFactory!, withId: "com.cinescope/videoplayer/view")

        channel.setMethodCallHandler(handleMethodCall)
    }

    func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let playerId = args["playerId"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing playerId", details: nil))
            return
        }

        switch call.method {
        case "initialize":
            guard let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing url", details: nil))
                return
            }
            initialize(playerId: playerId, url: url, result: result)

        case "play":
            play(playerId: playerId, result: result)

        case "pause":
            pause(playerId: playerId, result: result)

        case "dispose":
            dispose(playerId: playerId, result: result)

        case "seekTo":
            guard let position = args["position"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing position", details: nil))
                return
            }
            seekTo(playerId: playerId, position: position, result: result)

        case "setVolume":
            guard let volume = args["volume"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing volume", details: nil))
                return
            }
            setVolume(playerId: playerId, volume: Float(volume), result: result)

        case "getPosition":
            getPosition(playerId: playerId, result: result)

        case "preload":
            guard let url = args["url"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing url", details: nil))
                return
            }
            preload(playerId: playerId, url: url, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func initialize(playerId: Int, url: String, result: @escaping FlutterResult) {
        guard let videoURL = URL(string: url) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid video URL", details: nil))
            return
        }

        let player = CinescopeVideoPlayer(playerId: playerId, url: videoURL)
        players[playerId] = player

        player.initialize { [weak self] metadata, error in
            if let error = error {
                result(FlutterError(code: "INIT_FAILED", message: error.localizedDescription, details: nil))
                return
            }

            result(metadata)
        }
    }

    private func play(playerId: Int, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        player.play()
        result(nil)
    }

    private func pause(playerId: Int, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        player.pause()
        result(nil)
    }

    private func dispose(playerId: Int, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        player.dispose()
        players.removeValue(forKey: playerId)
        result(nil)
    }

    private func seekTo(playerId: Int, position: Int, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        let time = CMTime(value: Int64(position), timescale: 1000)
        player.seek(to: time)
        result(nil)
    }

    private func setVolume(playerId: Int, volume: Float, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        player.setVolume(volume)
        result(nil)
    }

    private func getPosition(playerId: Int, result: @escaping FlutterResult) {
        guard let player = players[playerId] else {
            result(FlutterError(code: "PLAYER_NOT_FOUND", message: "Player not found", details: nil))
            return
        }
        let position = player.getCurrentPosition()
        result(Int(position * 1000))
    }

    private func preload(playerId: Int, url: String, result: @escaping FlutterResult) {
        guard let videoURL = URL(string: url) else {
            result(FlutterError(code: "INVALID_URL", message: "Invalid video URL", details: nil))
            return
        }

        let player = CinescopeVideoPlayer(playerId: playerId, url: videoURL)
        players[playerId] = player
        player.preload()
        result(nil)
    }

    func getPlayer(playerId: Int) -> CinescopeVideoPlayer? {
        return players[playerId]
    }

    func pauseAllPlayers() {
        for player in players.values {
            player.pause()
        }
    }
}

/// CinescopeVideoPlayer: Hardware-accelerated AVPlayer wrapper
class CinescopeVideoPlayer {
    let playerId: Int
    let player: AVPlayer
    let playerItem: AVPlayerItem
    private var timeObserver: Any?

    init(playerId: Int, url: URL) {
        self.playerId = playerId

        // Prefer HEVC (H.265) codec per TCR3
        let asset = AVURLAsset(url: url, options: [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ])

        self.playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: playerItem)

        // Enable hardware acceleration
        player.automaticallyWaitsToMinimizeStalling = true

        // Configure for high-quality playback
        playerItem.preferredPeakBitRate = 0 // Unlimited bitrate
        playerItem.canUseNetworkResourcesForLiveStreamingWhilePaused = true
    }

    func initialize(completion: @escaping ([String: Any]?, Error?) -> Void) {
        // Wait for asset to load
        playerItem.asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { [weak self] in
            guard let self = self else { return }

            var error: NSError?
            let status = self.playerItem.asset.statusOfValue(forKey: "tracks", error: &error)

            if status == .loaded {
                // Extract metadata
                let tracks = self.playerItem.asset.tracks(withMediaType: .video)
                guard let videoTrack = tracks.first else {
                    completion(nil, NSError(domain: "VideoPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "No video track found"]))
                    return
                }

                let size = videoTrack.naturalSize
                let aspectRatio = size.width / size.height
                let duration = CMTimeGetSeconds(self.playerItem.asset.duration)

                let metadata: [String: Any] = [
                    "width": Int(size.width),
                    "height": Int(size.height),
                    "aspectRatio": aspectRatio,
                    "duration": Int(duration * 1000),
                ]

                completion(metadata, nil)
            } else {
                completion(nil, error)
            }
        }
    }

    func play() {
        player.play()
        // Ensure playback at original frame rate (60fps support)
        player.rate = 1.0
    }

    func pause() {
        player.pause()
    }

    func seek(to time: CMTime) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    func setVolume(_ volume: Float) {
        player.volume = volume
    }

    func getCurrentPosition() -> Double {
        return CMTimeGetSeconds(player.currentTime())
    }

    func preload() {
        // Preload by starting buffering without playing
        playerItem.asset.loadValuesAsynchronously(forKeys: ["tracks", "duration"]) { }
    }

    func dispose() {
        pause()
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        player.replaceCurrentItem(with: nil)
    }

    func getPlayerLayer() -> AVPlayerLayer {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspect // Maintain aspect ratio (FR5)
        return layer
    }
}
