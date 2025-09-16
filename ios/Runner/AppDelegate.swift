import Flutter
import UIKit
import GoogleMaps
import AVFoundation
import MediaPlayer

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback)
    } catch {
      print("Failed to set audio session category: \(error)")
    }
    do {
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to activate audio session: \(error)")
    }
    application.beginReceivingRemoteControlEvents()
    GMSServices.provideAPIKey("AIzaSyCWGXrDv1nBR5YWb4M2OTFcmwbPX7carIM")
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "radio/now_playing",
        binaryMessenger: controller.binaryMessenger
      )

      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "updateNowPlaying":
          guard let args = call.arguments as? [String: Any],
            let title = args["title"] as? String,
            let artist = args["artist"] as? String
          else {
            result(FlutterError(
              code: "INVALID_ARGUMENTS",
              message: "Expected title and artist",
              details: nil
            ))
            return
          }

          var artworkImage: UIImage?
          if let artworkData = args["artwork"] as? FlutterStandardTypedData {
            artworkImage = UIImage(data: artworkData.data)
          }

          DispatchQueue.main.async {
            var nowPlayingInfo: [String: Any] = [
              MPMediaItemPropertyTitle: title,
              MPMediaItemPropertyArtist: artist,
            ]

            if let image = artworkImage {
              nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
            }

            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
          }

          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
